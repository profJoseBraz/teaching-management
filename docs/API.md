# API — Contratos REST

Base URL: `/api/v1`  
Swagger UI: `http://localhost:3333/api/docs`  
OpenAPI JSON: `http://localhost:3333/api/docs.json`

## Convenções

| Item | Padrão |
|------|--------|
| Sucesso | `{ "data": ..., "meta": ...? }` |
| Erro | `{ "error": { "code", "message", "details?" } }` |
| Auth | `Authorization: Bearer <accessToken>` |
| Isolamento | `teacherId` vem do JWT (`sub`); nunca do body |

## Implementado (v0.1)

### `GET /health`
Health check público.

### `POST /auth/register`
Cria professor (`role=PROFESSOR`) e retorna tokens.

### `POST /auth/login`
Autentica e retorna `{ user, tokens }`.

### `GET /auth/me`
Retorna o usuário autenticado.

### Academic structure (`src/modules/academic`)

- `GET/POST /academic-years`
- `PATCH /academic-years/{id}`
- `POST /academic-years/{id}/set-current` — marca o ano como atual e desmarca os demais do professor (atômico)
- `GET/POST /courses` · `PATCH/DELETE /courses/{id}` (`DELETE` = soft delete)
- `GET/POST /disciplines` · `PATCH/DELETE /disciplines/{id}` (`DELETE` = soft delete)
- `GET/POST /courses/{courseId}/disciplines` (body `{ disciplineId }`) — vincula disciplina ao curso
- `DELETE /courses/{courseId}/disciplines/{disciplineId}` — desvincula (soft delete do vínculo)
- `GET /assessment-periods?academicYearId=` · `POST /assessment-periods`
- `PATCH /assessment-periods/{id}`
- `PUT /assessment-periods/reorder` (body `{ academicYearId, orderedIds: string[] }`)

Regras de domínio: `year` único por professor; `name` único por professor em `Course`/`Discipline`;
`sortOrder` é atribuído automaticamente na criação e recalculado via `reorder` (deve conter exatamente os
ids existentes do ano letivo, sem repetição).

### Students (`src/modules/students`)

- `GET /students?search=` · `POST /students`
- `GET/PATCH/DELETE /students/{id}` (`DELETE` = soft delete)

### Classes & Enrollments (`src/modules/classes`)

- `GET /classes?academicYearId=&courseId=&disciplineId=&status=` · `POST /classes`
- `GET/PATCH /classes/{id}`
- `POST /classes/{id}/archive` — define `status=ARCHIVED` preservando histórico
- `GET /classes/{classId}/enrollments` · `POST /classes/{classId}/enrollments` (body `{ studentId }`)
- `DELETE /classes/{classId}/enrollments/{studentId}` — define `status=WITHDRAWN` (não remove o histórico)
- `GET /classes/{classId}/disciplines` — lista disciplinas vinculadas à turma (`ClassDiscipline`)
- `POST /classes/{classId}/disciplines` (body `{ disciplineId }`) — vincula disciplina adicional à turma
- `DELETE /classes/{classId}/disciplines/{disciplineId}` — desvincula (soft delete do vínculo)

**Decisão de design:** uma turma ministra **N disciplinas** simultaneamente via `ClassDiscipline`
(`Class` não possui mais `disciplineId` direto). `POST /classes` aceita `disciplineIds: string[]`
(mín. 1) e cria a turma + os vínculos `ClassDiscipline` em uma única chamada; `disciplineId` singular
é aceito por compatibilidade e normalizado em `disciplineIds`. As respostas de `Create/Get/List/Update/
Archive Class` incluem `disciplineIds` e um resumo `disciplines: { id, name }[]`.

Regras de domínio: `CreateClass` valida que ano letivo, curso e todas as disciplinas pertencem ao
professor autenticado; `(teacherId, academicYearId, courseId, name)` é único; `?disciplineId=` em
`GET /classes` filtra turmas com vínculo ativo àquela disciplina (`classDisciplines.some`); `EnrollStudent`
reativa matrícula `WITHDRAWN` existente em vez de duplicá-la.

### Lessons (`src/modules/lessons`)

- `GET /classes/{classId}/lessons` (aceita filtro `?disciplineId=`) · `POST /classes/{classId}/lessons`
- `GET/PATCH/DELETE /lessons/{id}` (`DELETE` = soft delete)

Regras de domínio: `disciplineId` é obrigatório na criação e deve corresponder a um vínculo `ClassDiscipline`
ativo da turma; `endTime` deve ser estritamente posterior a `startTime` (formato `HH:mm`).

### Contents (`src/modules/contents`)

- `GET/POST /classes/{classId}/contents` (`GET` aceita filtros `?status=` e `?disciplineId=`)
- `PATCH /contents/{id}`
- `POST /contents/{id}/complete` | `POST /contents/{id}/reopen`
- `POST /lessons/{lessonId}/contents` (body `{ contentId }`) — vincula conteúdo à aula (mesma turma)
- `DELETE /lessons/{lessonId}/contents/{contentId}` — desvincula

Regra de domínio: `disciplineId` é obrigatório na criação e deve corresponder a um vínculo `ClassDiscipline`
ativo da turma.

### Attendance (`src/modules/attendance`)

- `GET /lessons/{lessonId}/attendance` — folha de chamada (matrículas ativas + status atual)
- `PUT /lessons/{lessonId}/attendance` — salva chamada em lote (upsert por aluno; body `{ records: [...] }`)
- `POST /lessons/{lessonId}/attendance/complete` — marca `lesson.attendanceCompleted = true`

**Decisão de design:** `CompleteAttendance` exige que **todos** os alunos com matrícula ativa já tenham
registro de chamada (via `SaveAttendance`); caso contrário retorna `422 VALIDATION_ERROR` listando os
alunos pendentes. Não há preenchimento automático como `PRESENT`.

### Activities (`src/modules/activities`)

- `GET /classes/{classId}/activities` (aceita filtro `?disciplineId=`) · `POST /classes/{classId}/activities`
- `GET/PATCH /activities/{id}` (`GET` inclui submissions + resumo agregado)
- `POST /activities/{id}/groups` — cria/substitui grupos (`mode=GROUP`) e atribui `groupId` às submissions
- `GET /activities/{id}/submissions`
- `PATCH /submissions/{id}` — marca `SUBMITTED`
- `POST /submissions/{id}/grade` — avalia individualmente (`score` entre `0` e `maxScore`)
- `POST /activities/{activityId}/groups/{groupId}/grade-shared` — avalia grupo (`gradeMode=SHARED`), aplica a mesma nota a todos os membros

**Decisões de design:**
- A criação de atividade sempre gera `Submission` `PENDING` para todos os alunos com matrícula ativa na
  turma, independentemente de `mode` ser `INDIVIDUAL` ou `GROUP`. Para `GROUP`, o `groupId` é atribuído
  posteriormente via `CreateActivityGroups`, sem bloquear a criação da atividade.
- `disciplineId` no body é opcional: quando ausente, é herdado de `originLessonId.disciplineId`; quando
  informado, deve ser idêntico ao da aula de origem e estar vinculado (`ClassDiscipline` ativo) à turma.

### Insights & Dashboard (`src/modules/insights`)

- `GET /dashboard?academicYearId=&classId=` — `AttentionItem[]` (Insights Engine) + resumo (`summary`)
- `GET /attention-items?academicYearId=&classId=` — mesma lista de `AttentionItem[]`, sem o resumo

Ambos os endpoints filtram sempre por `teacherId` (do JWT) e, opcionalmente, por `academicYearId`/`classId`.
Cada `AttentionItem` representa um tipo agregado (não uma linha por ocorrência); `count` indica quantos
registros compõem a pendência e `filters` traz os parâmetros para navegar à tela correspondente.

Tipos implementados (docs/ARCHITECTURE.md §9) e a regra por trás de cada contagem:

| Tipo | Severidade | Regra |
|------|-----------|-------|
| `LESSONS_WITHOUT_ATTENDANCE` | high | Aulas com `date <= hoje` e `attendanceCompleted = false` |
| `OVERDUE_UNGRADED_ACTIVITIES` | high | Atividades com `dueDate < hoje` e alguma submission não `GRADED` |
| `ACTIVITIES_AWAITING_GRADE` | high | Submissions com status `SUBMITTED` (fila de correção, qualquer prazo) |
| `CONTENTS_IN_PROGRESS` | medium | Conteúdos com status `IN_PROGRESS` |
| `STUDENTS_PENDING_SUBMISSION` | medium | Submissions `PENDING` de atividades com `dueDate <= hoje` |
| `ABSENT_ON_ACTIVITY_LESSON` | medium | Submission `PENDING` + `Attendance.status = ABSENT` na `originLesson` da atividade |
| `EXCESS_ABSENCES` | high | Alunos com faltas (`ABSENT`) `>= 5` no escopo filtrado |
| `ACTIVITIES_WITHOUT_SCORE` | medium | Atividades com `dueDate >= hoje` e alguma submission `SUBMITTED` sem `score` |

`EXCESS_ABSENCES` usa limiar fixo de 5 faltas no Dashboard; o relatório `excess-absences` aceita um
`threshold` customizado via query string.

### Reports (`src/modules/reports`)

- `GET /reports/{reportType}?academicYearId=&courseId=&disciplineId=&classId=&assessmentPeriodId=&from=&to=`

Todos os filtros são opcionais e sempre combinados com `teacherId` do JWT. `from`/`to` filtram a data mais
relevante para cada relatório (data da aula, `dueDate` da atividade ou `startedAt` do conteúdo).

**Tipos implementados (P0 — docs/ARCHITECTURE.md §17):**

| `reportType` | Descrição |
|--------------|-----------|
| `excess-absences` | Alunos com faltas `>= threshold` (default `5`), por turma |
| `pending-activities` | Entregas `PENDING` (aluno ainda não entregou) |
| `ungraded-activities` | Atividades vencidas com entregas ainda não corrigidas |
| `contents-in-progress` | Conteúdos com status `IN_PROGRESS` |
| `lessons-without-attendance` | Aulas já ocorridas sem chamada concluída |
| `absence-vs-non-submission` | Alunos com entrega `PENDING` que faltaram na aula de origem da atividade |

**Tipos implementados (P1):**

| `reportType` | Descrição |
|--------------|-----------|
| `attendance-percentage` | % de presença por aluno, por turma |
| `class-average` | Média das entregas corrigidas, por turma |
| `grades-by-student` | Nota de cada aluno por atividade |
| `attendance-by-student` | Presença agregada por aluno (todas as turmas do escopo) |
| `submission-status` | Contagem de entregas por status, por atividade |
| `lessons-taught` | Total de aulas por turma e quantas já têm chamada concluída |
| `students-without-grade` | Alunos com entregas sem nota lançada, por turma |
| `average-by-activity` | Média e volume de entregas por atividade |

**Decisão de design:** `RunReportUseCase` despacha para um método dedicado do `ReportsRepository` por
`reportType` (nenhuma regra de negócio nos Controllers/Prisma fora da Infrastructure). Relatórios que
precisam cruzar dados sem relação direta no Prisma (`absence-vs-non-submission`) resolvem o cruzamento em
duas consultas comparadas em memória, já que não há uma FK entre `Submission` e `Attendance`.

Schemas de domínio (`Class`, `Lesson`, `Activity`, `AttentionItem`, `DashboardResponse`, `ReportResult`, etc.)
estão documentados em `components.schemas` do Swagger.

## Códigos HTTP

| Código | Uso |
|--------|-----|
| 200 / 201 / 204 | Sucesso |
| 400 | Erro de domínio genérico |
| 401 | Não autenticado |
| 403 | Sem permissão (papéis futuros) |
| 404 | Não encontrado (também para cross-teacher) |
| 409 | Conflito (e-mail duplicado, etc.) |
| 422 | Validação Zod |
| 500 | Erro interno (sem stacktrace) |
