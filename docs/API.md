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

### `POST /auth/refresh`
Body `{ refreshToken }`. Renova o par `accessToken`/`refreshToken` sem novo login.
Usado pelo app quando o access expira (`JWT_EXPIRES_IN`, default 15m); o refresh
dura `REFRESH_TOKEN_EXPIRES_IN` (default 7d). Resposta: `{ data: { tokens } }`.
`401` se o refresh for inválido ou expirado.

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
- `POST /students/bulk/preview` — resolve texto colado **sem gravar**
  (`{ candidates: NEW|EXISTING, skipped, totalParsed, totalExisting, totalNew }`)
- `POST /students/bulk` — cadastro em lote a partir de texto colado (`{ "text": "..." }`)
  - Aceita um nome por linha **ou** registros com Matrícula/Nome/E-mail/Telefone/Obs
  - Separadores: tab, `;` ou `,` — com ou sem cabeçalho (`Matrícula;Nome;E-mail`)
  - Ordem posicional (sem cabeçalho): `Matrícula;Nome;E-mail;Telefone;Obs`
  - Resposta: `{ created, skipped, totalParsed, totalCreated }`
  - Matrícula duplicada (mesmo professor, aluno ativo) → linha em `skipped` com
    `"Aluno já cadastrado com esta matrícula."`
- `POST /students/batch` — cria alunos a partir de lista estruturada (pós-confirmação na UI)
- `GET/PATCH/DELETE /students/{id}` (`DELETE` = soft delete)
- `POST/PATCH` com `registryCode` já usado → `409` `"Aluno já cadastrado com esta matrícula."`
  (unicidade case-insensitive por professor; alunos soft-deleted não bloqueiam)
- No app (Turma → Alunos → **Colar lista**): `preview` → tela de confirmação com checkboxes
  → `batch` (novos) + `enrollments/bulk` (selecionados)

### Agenda (`src/modules/agenda`)

Anotações do professor: **várias anotações distintas por data** (`agenda_notes`).
Status `completed` (padrão `false` = não concluída). Agrupamento por dia é só na UI.

- `GET /agenda-notes?from=&to=&search=&completed=` — lista (data desc, depois criação desc);
  `completed=true|false` filtra por status; omitido = todas
- `POST /agenda-notes` — cria sempre uma nova anotação (`{ date, content, completed? }`)
- `GET/PATCH/DELETE /agenda-notes/{id}` — leitura, alteração (data/conteúdo/`completed`) e exclusão definitiva

### Classes & Enrollments (`src/modules/classes`)

- `GET /classes?academicYearId=&courseId=&disciplineId=&status=` · `POST /classes`
- `GET/PATCH /classes/{id}`
- `POST /classes/{id}/archive` — define `status=ARCHIVED` preservando histórico
- `GET /classes/{classId}/enrollments` · `POST /classes/{classId}/enrollments` (body `{ studentId }`)
- `POST /classes/{classId}/enrollments/bulk` (body `{ studentIds: string[] }`) — matricula vários alunos de uma vez; já matriculados ou inexistentes vão em `skipped`
- `DELETE /classes/{classId}/enrollments/{studentId}` — define `status=WITHDRAWN` (não remove o histórico)
- Listagens de alunos/matrículas/entregas vêm em **ordem alfabética** pelo nome do aluno
  (status da entrega não altera a posição na lista).
- `GET /classes/{classId}/disciplines` — lista disciplinas vinculadas à turma (`ClassDiscipline`)
- `POST /classes/{classId}/disciplines` (body `{ disciplineId }`) — vincula disciplina adicional à turma (deve estar na grade do curso)
- `DELETE /classes/{classId}/disciplines/{disciplineId}` — desvincula (soft delete do vínculo)

**Decisão de design:** uma turma ministra **N disciplinas** simultaneamente via `ClassDiscipline`
(`Class` não possui mais `disciplineId` direto). `POST /classes` aceita `disciplineIds: string[]`
(mín. 1) e cria a turma + os vínculos `ClassDiscipline` em uma única chamada; `disciplineId` singular
é aceito por compatibilidade e normalizado em `disciplineIds`. As respostas de `Create/Get/List/Update/
Archive Class` incluem `disciplineIds` e um resumo `disciplines: { id, name }[]`.

Regras de domínio: `CreateClass` / `LinkDisciplineToClass` exigem que cada disciplina esteja na grade
do curso (`CourseDiscipline` ativo); ano letivo, curso e disciplinas pertencem ao professor autenticado;
`(teacherId, academicYearId, courseId, name)` é único; `?disciplineId=` em `GET /classes` filtra turmas
com vínculo ativo àquela disciplina (`classDisciplines.some`); `EnrollStudent` reativa matrícula
`WITHDRAWN` existente em vez de duplicá-la.

### Lessons (`src/modules/lessons`)

- `GET /classes/{classId}/lessons` (filtros `?disciplineId=` e `?assessmentPeriodId=`) · `POST /classes/{classId}/lessons`
- `POST /classes/{classId}/lessons/bulk` (body `{ disciplineId, assessmentPeriodId, dates[], startTime, endTime, observations? }`) — cadastra várias aulas com o mesmo horário/disciplina/período (máx. 200 datas)
- `GET/PATCH/DELETE /lessons/{id}` (`DELETE` = soft delete; `PATCH` aceita `assessmentPeriodId` para mover a aula de período)

Regras de domínio: `disciplineId` e `assessmentPeriodId` são obrigatórios na criação;
`disciplineId` deve corresponder a um vínculo `ClassDiscipline` ativo da turma;
`assessmentPeriodId` deve pertencer ao ano letivo da turma (e ao professor);
`endTime` deve ser estritamente posterior a `startTime` (formato `HH:mm`).

### Contents (`src/modules/contents`)

- `GET/POST /classes/{classId}/contents` (`GET` aceita `?status=`, `?disciplineId=` e `?assessmentPeriodId=`)
- `PATCH /contents/{id}` (aceita `assessmentPeriodId` para mover o conteúdo de período)
- `POST /contents/{id}/complete` | `POST /contents/{id}/reopen`
- `POST /lessons/{lessonId}/contents` (body `{ contentId }`) — vincula conteúdo à aula (mesma turma)
- `DELETE /lessons/{lessonId}/contents/{contentId}` — desvincula

Regra de domínio: `disciplineId` e `assessmentPeriodId` são obrigatórios na criação;
`disciplineId` deve estar vinculado à turma; o período deve pertencer ao ano letivo da turma.

### Attendance (`src/modules/attendance`)

- `GET /lessons/{lessonId}/attendance` — folha de chamada (matrículas ativas + status atual)
- `PUT /lessons/{lessonId}/attendance` — salva chamada em lote (upsert por aluno; body `{ records: [...] }`)
- `POST /lessons/{lessonId}/attendance/complete` — marca `lesson.attendanceCompleted = true`

**Decisão de design:** `CompleteAttendance` exige que **todos** os alunos com matrícula ativa já tenham
registro de chamada (via `SaveAttendance`); caso contrário retorna `422 VALIDATION_ERROR` listando os
alunos pendentes. Não há preenchimento automático como `PRESENT`.

### Rate limit

- Em `development`, o limite geral da API fica **desligado** (evita travar o app Flutter
  durante desenvolvimento).
- Em produção: `RATE_LIMIT_MAX` requests por `RATE_LIMIT_WINDOW_MS` (default 2000 / 15min).
- `POST /auth/login`, `/auth/register` e `/auth/refresh` têm limite próprio (30 / 15min), sempre ativo.
- Resposta `429`: `{ error: { code: "RATE_LIMIT_EXCEEDED", message: "..." } }`.

### Activities (`src/modules/activities`)

- `GET /classes/{classId}/activities` (filtros `?disciplineId=`, `?tag=` e `?assessmentPeriodId=`) · `POST /classes/{classId}/activities`
- `GET/PATCH/DELETE /activities/{id}` (`GET` inclui submissions + resumo agregado; `PATCH` aceita `assessmentPeriodId`; `DELETE` = soft delete da atividade + submissions/grupos)
- `POST /activities/{id}/mark-evaluated` — marca a atividade como Avaliada (`evaluated=true`)
- `POST /activities/{id}/reopen-evaluation` — reabre a correção (`evaluated=false`)
- `POST /activities/{id}/groups` — cria/substitui grupos (`mode=GROUP`) e atribui `groupId` às submissions
- `GET /activities/{id}/submissions`
- `POST /activities/{id}/submissions/grade-bulk` — mesma nota para várias entregas
  (body `{ submissionIds: uuid[], score, observations? }`, máx. 200; todas devem ser da atividade)
- `PATCH /submissions/{id}` (body `{ status: 'PENDING' | 'SUBMITTED' }`) — PENDING ↔ SUBMITTED;
  também permite `GRADED → PENDING` (limpa nota/observações). `GRADED → SUBMITTED` não é permitido.
- `POST /submissions/{id}/grade` — avalia individualmente (`score` entre `0` e `maxScore`)
- `POST /activities/{activityId}/groups/{groupId}/grade-shared` — avalia grupo (`gradeMode=SHARED`), aplica a mesma nota a todos os membros

**Decisões de design:**
- A criação de atividade sempre gera `Submission` `PENDING` para todos os alunos com matrícula ativa na
  turma, independentemente de `mode` ser `INDIVIDUAL` ou `GROUP`. Para `GROUP`, o `groupId` é atribuído
  posteriormente via `CreateActivityGroups`, sem bloquear a criação da atividade.
- `originLessonId` no body é opcional (atividade pode existir sem aula de origem).
- `assessmentPeriodId` é obrigatório na criação e deve pertencer ao ano letivo da turma.
- `evaluated` / `evaluatedAt`: o professor confirma o encerramento da avaliação da atividade
  (independente de ainda haver submissions `PENDING`). Atividades Avaliadas saem do insight
  `OVERDUE_UNGRADED_ACTIVITIES` e do relatório de atividades sem correção.
- `description` aceita até 5000 caracteres (`VARCHAR(5000)`), em **Markdown**
  (negrito, itálico, títulos, listas). O cliente renderiza na leitura; o backend
  armazena o texto bruto sem interpretar a marcação.
- `tag` (opcional, até 80 chars): rótulo livre para agrupar várias atividades
  (ex.: `"Prova 1"`). Listagem aceita `?tag=` (case-insensitive).
- `disciplineIds: string[]` (forma preferida): a mesma atividade pode vincular-se a várias
  disciplinas da turma (ex.: LP I e LP II). Sem `originLessonId`, mín. 1. Com aula de origem, a
  disciplina da aula é incluída automaticamente; outras podem ser adicionadas. Todas devem estar
  em `ClassDiscipline` ativo. `disciplineId` singular é aceito por compatibilidade e normalizado
  em `disciplineIds`. Respostas de Create/Get/List/Update incluem `disciplineIds`.
  `GET ?disciplineId=` filtra atividades que tenham aquele vínculo ativo.
  `PATCH` aceita `disciplineIds` para substituir os vínculos.

### Evaluation Models (`src/modules/evaluation-models`)

Catálogo reutilizável de itens avaliativos (Config). Independente de turmas. Sem lógica especial por nome.

- `GET /evaluation-models?includeInactive=` · `POST /evaluation-models`
- `GET/PATCH/DELETE /evaluation-models/{id}` — delete = soft delete **bloqueado** se houver composição ativa
- `POST /evaluation-models/{id}/deactivate` — `isActive=false` (preferível à exclusão quando em uso)
- `POST /evaluation-models/{id}/items` · `PATCH/DELETE .../items/{itemId}`
  - Item de recuperação: `{ isRecovery: true, recoversItemId }` (item regular do mesmo modelo)
- `PUT /evaluation-models/{id}/items/reorder` — body `{ itemIds: uuid[] }`

Remover item (soft delete) remove automaticamente os grupos de composição que o referenciam
(e também recuperações vinculadas a um item regular removido).

### Grade Compositions (`src/modules/grade-compositions`)

Escopo: **turma + disciplina + período avaliativo**. O `evaluationModelId` fica associado ao contexto.

- `GET /grade-compositions?classId=&disciplineId=&assessmentPeriodId=` — composição (ou `null`) +
  atividades elegíveis + sync com itens do modelo
- `PUT /grade-compositions` — upsert completo (`evaluationModelId` + grupos/atividades/pesos)
- `DELETE /grade-compositions/{id}` — soft delete (bloqueado se `FINALIZED`)
- `GET /grade-compositions/{id}/calculate` — notas convertidas por aluno/grupo (`null` se sem nota)

Cálculo: `(score / activity.maxScore) * 100` → média (simples/ponderada) → escala para `item.maxScore` →
arredonda **para cima** (inteiro). Sem nota em todas as atividades do grupo → `null`. Com pelo menos uma nota,
faltantes entram como 0 na média. Para item regular com recuperação vinculada, `consideredScore` =
`max(convertedScore, recovery.convertedScore)`. `finalAverage` (0–100) =
`(soma consideredScore dos itens regulares / soma maxScore) * 100` (máximas → 100). Pesos obrigatórios
e > 0 na média ponderada.

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
