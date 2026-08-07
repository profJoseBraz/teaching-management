# Gestão Docente — Especificação Arquitetural

> Documento base da arquitetura. Nenhuma implementação deve divergir deste desenho sem revisão arquitetural explícita.

**Versão:** 1.0  
**Data:** 2026-08-03  
**Stack:** Flutter + Riverpod · Node.js + Express + TypeScript · PostgreSQL + Prisma · JWT

---

## 1. Visão do produto

O **Gestão Docente** é um assistente da rotina do professor — não um diário eletrônico institucional.

### Problema

O professor espalha o semestre em planilhas, anotações e arquivos. Esquece lançar frequência, corrigir atividades e fechar conteúdos. A informação existe, mas não chega até ele no momento certo.

### Promessa

Centralizar a rotina letiva e **empurrar pendências** para o professor. O Dashboard é a tela principal: ações, não apenas indicadores.

### Princípios de produto

1. **Pendência primeiro** — o sistema destaca o que exige ação.
2. **Poucos cliques** — fluxos curtos para frequência, nota e conteúdo.
3. **Contexto automático** — cruzar frequência × entrega × aula × conteúdo.
4. **Histórico preservado** — anos letivos nunca se perdem.
5. **Simplicidade operacional** — complexidade fica na arquitetura, não na UI.

---

## 2. Decisões arquiteturais (e por quê)

| Decisão | Escolha | Justificativa |
|--------|---------|---------------|
| Estilo | Clean Architecture + Use Cases + Repository | Regras de negócio testáveis e desacopladas de Express/Prisma/Flutter |
| Backend | Node.js + Express + TypeScript | Alinhado ao padrão do projeto; tipagem forte; ecossistema maduro |
| ORM | Prisma | Migrations, tipagem e produtividade sem vazar para Use Cases |
| Validação | Zod (borda) + regras no Domain/UseCase | Contrato de entrada separado da regra de negócio |
| Auth | JWT + bcrypt + refresh | Access curto + refresh; renovação silenciosa no cliente |
| Frontend state | Riverpod | Providers tipados, testáveis, sem acoplar UI à API |
| HTTP client | Dio | Interceptors (auth, erro), alinhado às rules do projeto |
| UI | Material Design 3 | Consistência, light/dark, componentes familiares |
| Multi-tenant | `teacherId` em toda entidade de negócio + filtro obrigatório no repositório | Isolamento por professor sem microserviços |
| Papéis futuros | Enum `UserRole` + autorização por política (stub) | Evolui para Admin/Coord/Secretaria sem remodelar identidade |
| Relatórios/Insights | Use Cases de leitura (queries otimizadas), sem materializar tudo | Flexível; cache só se performance exigir |

---

## 3. Proposta de domínio: “Etapa” → **Período Avaliativo**

### Problema com “Etapa”

Em educação brasileira, **etapa** costuma significar nível de ensino (Fundamental, Médio, etc.). Usar “Etapa” para bimestre/semestre gera ambiguidade.

### Proposta

Adotar **Período Avaliativo** (`AssessmentPeriod`):

- Exemplos: `1º Bimestre`, `2º Bimestre`, `1º Semestre`, `Recuperação`
- Pertence a um **Ano Letivo**
- Nome, ordem e datas definidos pelo professor
- Filtro padrão em notas, atividades e relatórios

### Por que no Ano Letivo (e não na Turma)?

No MVP, turmas do mesmo ano geralmente compartilham a mesma estrutura (bimestres). Isso reduz cadastro repetido.

**Extensão futura (sem breaking change):** campo opcional `classId` em `AssessmentPeriod`.  
`null` = período do ano; preenchido = override por turma.

---

## 4. Arquitetura da solução

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter (Presentation)                  │
│  Screens → Widgets → Riverpod Controllers/Notifiers         │
└────────────────────────────┬────────────────────────────────┘
                             │ HTTPS / JSON (REST)
┌────────────────────────────▼────────────────────────────────┐
│                Node.js API (Presentation)                   │
│         Routes → Controllers → Middlewares (JWT, Zod)       │
└────────────────────────────┬────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────┐
│                   Application (Use Cases)                   │
│     Auth · Academic · Class · Lesson · Attendance · …       │
│              Insights Engine · Reports                      │
└────────────────────────────┬────────────────────────────────┘
                             │ interfaces
┌────────────────────────────▼────────────────────────────────┐
│                         Domain                              │
│     Entities · Value Objects · Domain Services · Errors     │
└────────────────────────────┬────────────────────────────────┘
                             │ implements
┌────────────────────────────▼────────────────────────────────┐
│              Infrastructure (Prisma / PostgreSQL)           │
│         Repositories · Hash · JWT · Mail (futuro)           │
└─────────────────────────────────────────────────────────────┘
```

### Responsabilidades por camada

| Camada | Faz | Não faz |
|--------|-----|---------|
| **Presentation (API)** | HTTP, auth middleware, validação de input, status codes, Swagger | Regra de negócio, acesso Prisma |
| **Application** | Orquestra Use Cases, transações, autorização de dono | SQL/Prisma, detalhes de UI |
| **Domain** | Entidades, invariantes, VOs, erros de domínio | Framework, persistência |
| **Infrastructure** | Prisma repos, JWT, bcrypt, clock, e-mail futuro | Regra de negócio rica |
| **Presentation (Flutter)** | UI, navegação, estados visuais | Chamada HTTP direta na tela |

---

## 5. Módulos do sistema

| Módulo | Responsabilidade |
|--------|------------------|
| **Identity & Access** | Usuário, autenticação, papel (preparado) |
| **Academic Structure** | Ano letivo, curso, disciplina, vínculo curso↔disciplina, período avaliativo |
| **Class & Enrollment** | Turmas, matrículas (N:N aluno↔turma) |
| **Students** | Cadastro de alunos do professor |
| **Agenda** | Anotações pessoais do professor (várias por data) |
| **Lessons** | Aulas (encontros) |
| **Contents** | Conteúdos transversais a aulas + status |
| **Attendance** | Frequência por aula |
| **Activities** | Atividades, grupos, entregas, notas |
| **Evaluation Models** | Catálogo reutilizável de itens avaliativos (Config) |
| **Grade Compositions** | Agrupamento de atividades em itens do modelo por turma/disciplina/período + cálculo |
| **Insights** | Motor de pendências e cruzamentos (Dashboard) |
| **Reports** | Relatórios filtráveis |
| **Shared Kernel** | IDs, datas, paginação, erros, ownership |

Cada módulo no backend expõe Use Cases; a API apenas os adapta para HTTP.

---

## 6. Modelo de domínio

### 6.1 Diagrama de relacionamentos (conceitual)

```mermaid
erDiagram
  USER ||--o{ ACADEMIC_YEAR : owns
  USER ||--o{ COURSE : owns
  USER ||--o{ DISCIPLINE : owns
  USER ||--o{ STUDENT : owns
  USER ||--o{ CLASS : owns

  ACADEMIC_YEAR ||--o{ ASSESSMENT_PERIOD : has
  ACADEMIC_YEAR ||--o{ CLASS : contains

  COURSE ||--o{ COURSE_DISCIPLINE : has
  DISCIPLINE ||--o{ COURSE_DISCIPLINE : has
  COURSE ||--o{ CLASS : offered_as

  CLASS ||--o{ CLASS_DISCIPLINE : teaches
  DISCIPLINE ||--o{ CLASS_DISCIPLINE : taught_in

  CLASS ||--o{ ENROLLMENT : has
  STUDENT ||--o{ ENROLLMENT : has

  CLASS ||--o{ LESSON : has
  CLASS ||--o{ CONTENT : has
  CLASS ||--o{ ACTIVITY : has
  DISCIPLINE ||--o{ LESSON : classifies
  DISCIPLINE ||--o{ CONTENT : classifies
  DISCIPLINE ||--o{ ACTIVITY : classifies

  CONTENT ||--o{ LESSON_CONTENT : spans
  LESSON ||--o{ LESSON_CONTENT : covers

  LESSON ||--o{ ATTENDANCE : registers
  STUDENT ||--o{ ATTENDANCE : has

  LESSON ||--o{ ACTIVITY : originates
  ASSESSMENT_PERIOD ||--o{ ACTIVITY : groups
  ACTIVITY ||--o{ ACTIVITY_GROUP : may_have
  ACTIVITY_GROUP ||--o{ ACTIVITY_GROUP_MEMBER : has
  STUDENT ||--o{ ACTIVITY_GROUP_MEMBER : in
  ACTIVITY ||--o{ SUBMISSION : has
  STUDENT ||--o{ SUBMISSION : delivers
```

### 6.2 Agregados

Agregados definem fronteiras de consistência transacional.

| Agregado raiz | Entidades internas | Invariantes principais |
|---------------|--------------------|------------------------|
| **User** | — | E-mail único; senha hasheada; role válido |
| **AcademicYear** | AssessmentPeriods | Ano único por professor; períodos com ordem coerente |
| **Course** | — | Nome único por professor (normalizado) |
| **Discipline** | — | Nome único por professor |
| **CourseDiscipline** | — | Par curso+disciplina único |
| **Student** | — | Pertence a um professor |
| **Class** | Enrollments, ClassDisciplines | Curso+ano únicos por nome; N disciplinas via `ClassDiscipline`; aluno não duplicado na turma |
| **ClassDiscipline** | — | Par turma+disciplina único; soft delete (turma pode ganhar/perder disciplinas) |
| **Lesson** | Attendances | `disciplineId` obrigatório (vinculado à turma); horário final > inicial; 1 registro de frequência por aluno/aula |
| **Content** | LessonContents | `disciplineId` obrigatório (vinculado à turma); status OPEN/COMPLETED; conclusão só pelo professor |
| **Activity** | ActivityDisciplines, Groups, Members, Submissions | N disciplinas via `ActivityDiscipline` (mín. 1); nota ≤ máxima; grupo só se mode=GROUP |
| **EvaluationModel** | EvaluationModelItems | Catálogo do professor; itens com nome + maxScore + ordem; sem lógica especial por nome |
| **GradeComposition** | Groups, CompositionActivities | Único por turma+disciplina+período; modelo associado; cálculo live a partir de submissions |

**Ownership:** todo agregado de negócio carrega `teacherId`. Repositórios **sempre** filtram por ele.

### 6.3 Entidades e atributos essenciais

#### User
- `id`, `name`, `email`, `passwordHash`
- `role`: `PROFESSOR` (MVP) | `ADMIN` | `COORDINATOR` | `SECRETARY` (reservados)
- `isActive`, timestamps, `deletedAt?` (soft delete)

#### AcademicYear
- `id`, `teacherId`, `year` (int, ex.: 2026), `label?`, `isCurrent`, `startsOn?`, `endsOn?`

#### Course
- `id`, `teacherId`, `name`, `description?`

#### Discipline
- `id`, `teacherId`, `name`, `description?`

#### CourseDiscipline
- `id`, `teacherId`, `courseId`, `disciplineId`  
Disciplina **não** pertence a um único curso.

#### AssessmentPeriod
- `id`, `teacherId`, `academicYearId`, `name`, `sortOrder`, `startsOn?`, `endsOn?`

#### Class (Turma)
- `id`, `teacherId`, `academicYearId`, `courseId`
- `name` (ex.: “3º DS - Manhã”), `shift?` (MORNING/AFTERNOON/EVENING/NIGHT)
- `status`: ACTIVE | ARCHIVED

Constraint: único `(teacherId, academicYearId, courseId, name)`. Uma turma **não** possui mais
`disciplineId` direto — ela ministra N disciplinas via `ClassDiscipline` (ver abaixo). As aulas e
conteúdos da turma **são** por disciplina (`disciplineId` obrigatório). Atividades vinculam-se a
**uma ou mais** disciplinas via `ActivityDiscipline` (N:N).

#### ClassDiscipline
- `id`, `teacherId`, `classId`, `disciplineId`, `deletedAt?` (soft delete)  
Vínculo N:N entre turma e as disciplinas ministradas nela; par `(classId, disciplineId)` único.
Uma turma pode ganhar/perder disciplinas ao longo do tempo sem apagar o histórico de aulas/atividades
já lançadas para uma disciplina removida.

#### Student
- `id`, `teacherId`, `name`, `registryCode?` (único por professor entre ativos, case-insensitive), `email?`, `phone?`, `notes?`

#### Enrollment
- `id`, `teacherId`, `classId`, `studentId`, `status`: ACTIVE | WITHDRAWN  
Unique `(classId, studentId)`.

#### Lesson
- `id`, `teacherId`, `classId`, `disciplineId`, `assessmentPeriodId`, `date`, `startTime`, `endTime`, `observations?`
- `attendanceCompleted`: bool (denormalização controlada para Insights — ver §12)
- `disciplineId` deve corresponder a um vínculo `ClassDiscipline` ativo da turma.
- `assessmentPeriodId` deve pertencer ao ano letivo da turma (filtro padrão no AppBar).

#### Content
- `id`, `teacherId`, `classId`, `disciplineId`, `assessmentPeriodId`, `title`, `description?`
- `status`: IN_PROGRESS | COMPLETED
- `startedAt`, `completedAt?`
- `disciplineId` deve corresponder a um vínculo `ClassDiscipline` ativo da turma.
- `assessmentPeriodId` deve pertencer ao ano letivo da turma.

#### LessonContent
- `lessonId`, `contentId` (N:N) — conteúdo atravessa várias aulas.

#### Attendance
- `id`, `teacherId`, `lessonId`, `studentId`
- `status`: PRESENT | ABSENT | LATE
- `observations?`  
Unique `(lessonId, studentId)`.

#### Activity
- `id`, `teacherId`, `classId`, `originLessonId?`, `assessmentPeriodId`
- `disciplineIds` (via `ActivityDiscipline` N:N; mín. 1)
- `title` (até 200), `description?` (VARCHAR 5000, Markdown), `tag?` (VARCHAR 80, agrupamento)
- `category`: EXERCISE | ASSIGNMENT | PROJECT | RESEARCH | SEMINAR | EXAM | OTHER
- `mode`: INDIVIDUAL | GROUP
- `maxScore` (default 100)
- `createdOn`, `dueDate`
- `evaluated` (bool, default false), `evaluatedAt?` — professor confirma encerramento da avaliação
- `assessmentPeriodId` é obrigatório na criação (mesmo critério de aulas/conteúdos).
- `originLessonId` é opcional. Sem aula de origem, ao menos uma disciplina é obrigatória.
  Com aula de origem, a disciplina da aula entra automaticamente; outras disciplinas da turma
  podem ser adicionadas (ex.: mesma atividade para LP I e LP II). Todas devem estar vinculadas
  (`ClassDiscipline` ativo) à turma.
- `gradeMode` (quando GROUP): SHARED | INDIVIDUAL  
  — SHARED: mesma nota para o grupo; INDIVIDUAL: nota por aluno mesmo em grupo.

#### ActivityDiscipline
- `id`, `teacherId`, `activityId`, `disciplineId`, `deletedAt?` (soft delete)
- Vínculo N:N entre atividade e disciplinas; par `(activityId, disciplineId)` único.

#### ActivityGroup / ActivityGroupMember
- Grupo nomeado; membros = alunos da turma.

#### Submission (Entrega)
- `id`, `teacherId`, `activityId`, `studentId`, `groupId?`
- `status`: PENDING | SUBMITTED | GRADED
- `score?`, `observations?`, `submittedAt?`, `gradedAt?`  
Unique `(activityId, studentId)`.

#### EvaluationModel (Modelo Avaliativo)
- Catálogo reutilizável do professor (Config → Modelos avaliativos), **independente** de turmas.
- `id`, `teacherId`, `name`, `description?`, `isActive`, `sortOrder`
- Itens (`EvaluationModelItem`): `name`, `maxScore`, `sortOrder`
- Recuperação é explícita: `isRecovery` + `recoversItemId` (aponta ao item regular do mesmo modelo).
- Nota **considerada** do item regular = `max(nota regular, nota da recuperação vinculada)`.
  A coluna de recuperação continua mostrando a nota bruta da recuperação.

#### GradeComposition (Composição da Nota)
- Escopo: **Turma + Disciplina + Período avaliativo** (unique). Nunca mistura períodos.
- `evaluationModelId` — associa o modelo ao contexto para reabrir a tela já com o modelo escolhido.
- `status`: `DRAFT` (padrão) | `FINALIZED` (reservado; ver §6.4).
- `finalizedAt?` — preenchido só no futuro fechamento.
- Grupos (`GradeCompositionGroup`): referência a `evaluationModelItemId` + `calculationMethod`
  (`SIMPLE_AVERAGE` | `WEIGHTED_AVERAGE`). **Sem** `sortOrder` próprio — a ordem vem do item do modelo.
- Atividades no grupo (`GradeCompositionActivity`): `activityId`, `weight?` (obrigatório se média ponderada).
- Uma atividade entra em **no máximo um** grupo da mesma composição.
- Cálculo **live**: normaliza `(score / activity.maxScore) * 100`, aplica média, escala para `item.maxScore`.
- Resultado do item arredondado **sempre para cima** (teto) até inteiro — sem casas decimais.
- Sem nota em **todas** as atividades do grupo → resultado `null` (não confundir com zero).
- Se há pelo menos uma nota no grupo, atividades sem nota entram como **0** na média
  (entrega faltante reduz a nota do item; zero explícito continua sendo zero avaliado).
- Auditoria de edição: `updatedAt` (+ `teacherId` do registro). Sem `updatedByTeacherId` (app single-teacher).

### 6.4 Decisões — Modelo Avaliativo & Composição da Nota

#### Exclusão de modelos
- **Hard/soft delete bloqueado** se existir qualquer `GradeComposition` ativa (`deletedAt = null`)
  referenciando o modelo → `ConflictError`.
- Alternativa sempre disponível: **desativar** (`isActive = false`). Modelos inativos não aparecem
  para *novas* associações; composições já existentes continuam funcionando.
- Remoção de **item** do modelo: soft delete do item + sincronização (abaixo).

#### Sincronização quando o modelo muda (composições existentes)
Composições **não** versionam o modelo. A sincronização roda no GET da composição e antes do cálculo:

| Alteração no modelo | Efeito na composição |
|---------------------|----------------------|
| Novo item | Cria `GradeCompositionGroup` vazio (`SIMPLE_AVERAGE`), sem atividades |
| Item removido (soft delete) | Remove o grupo correspondente e libera as atividades daquele grupo |
| Reordenar itens | Automático — UI/API ordenam por `EvaluationModelItem.sortOrder` |
| Renomear item / alterar `maxScore` | Automático via FK; cálculo usa valores atuais do item |
| Trocar o modelo da composição | Substitui todos os grupos pelos itens do novo modelo (atividades perdidas do mapeamento anterior) |

Composição com `status = FINALIZED` (futuro) **não** sincroniza nem aceita PUT — ver preparação abaixo.

#### Associação do modelo ao contexto
`GradeComposition.evaluationModelId` é a fonte da verdade do “modelo desta turma/disciplina/período”.
Não é necessário um vínculo separado modelo↔turma.

#### Preparação para fechamento/congelamento (não implementado)
Objetivo futuro: gerar versão auditável das notas e impedir que mudanças em atividades alterem o
resultado exibido como “fechado”.

Já no schema:
- `GradeComposition.status` (`DRAFT` | `FINALIZED`)
- `GradeComposition.finalizedAt`

Extensão prevista **sem** refatorar o cálculo live:
1. Use case `FinalizeGradeComposition` — só se `DRAFT`; grava snapshot em tabela futura
   `GradeCompositionFrozenScore` (aluno × grupo × score convertido, metadados).
2. Leituras “oficiais” passam a preferir o snapshot quando `FINALIZED`.
3. Cálculo live permanece disponível para rascunho / reabertura administrativa.
4. PUT/sync/delete bloqueados enquanto `FINALIZED` (exceto `Reopen` explícito).

Até lá, apenas `DRAFT` é usado; `FINALIZED` existe para evitar migração estrutural depois.

---

## 7. Regras de negócio centrais

### Ownership e isolamento
1. Toda leitura/escrita de negócio exige `teacherId` do token.
2. IDs de outras entidades não autorizam acesso cross-teacher (verificar dono no Use Case/repositório).
3. Um professor nunca lista/obtém dados de outro.

### Ano letivo e histórico
4. Turmas pertencem a um ano letivo.
5. Arquivar/trocar ano atual **não apaga** histórico.
6. Soft delete preferível a hard delete em entidades com histórico (aluno, turma, aula, atividade).

### Estrutura acadêmica
7. Disciplina pode vincular-se a N cursos via `CourseDiscipline`.
8. Turma referencia curso + ano; ministra N disciplinas via `ClassDiscipline` (par turma+disciplina único, soft delete).
   Toda disciplina vinculada à turma **deve** estar na grade do curso (`CourseDiscipline` ativo).
9. Aluno ↔ Turma é N:N via `Enrollment`.

### Aulas e conteúdos
10. Aula pertence a uma turma, uma disciplina e um período avaliativo (`assessmentPeriodId` obrigatório na criação); intervalo horário válido; a disciplina deve estar vinculada (`ClassDiscipline` ativo) à turma; o período deve ser do ano letivo da turma.
11. Conteúdo nasce na turma para uma disciplina e um período específicos (`disciplineId` + `assessmentPeriodId` obrigatórios); pode ligar-se a N aulas.
12. Conteúdo permanece `IN_PROGRESS` até o professor marcar `COMPLETED`.
13. Remover vínculo aula↔conteúdo não apaga o conteúdo automaticamente.

### Frequência
14. Frequência é por aula e por aluno.
15. Quatro aulas consecutivas ausentes = quatro faltas.
16. Status: PRESENT | ABSENT | LATE.
17. Lançar frequência marca a aula como `attendanceCompleted = true` quando todos os alunos ativos tiverem registro (ou quando o professor confirmar “concluir chamada”).

### Atividades e entregas
18. Atividade pode opcionalmente ligar-se a uma aula (`originLessonId`); vive além dela via `dueDate`.
   Disciplinas são N:N (`ActivityDiscipline`): mín. 1 sem aula de origem; com aula, a disciplina
   da aula é incluída automaticamente e outras da turma podem ser adicionadas. Todas devem estar
   vinculadas (`ClassDiscipline` ativo). Insights que cruzam ausência na aula de origem só
   consideram atividades com `originLessonId`.
19. Ao criar atividade, gerar `Submission PENDING` para cada aluno ativo da turma (individual) ou conforme grupos.
20. Nota não pode exceder `maxScore` nem ser negativa.
21. Em GROUP + SHARED, aplicar a mesma nota a todos os membros do grupo.
22. Em GROUP + INDIVIDUAL, cada submission tem nota própria.
23. Transições de entrega: PENDING ↔ SUBMITTED → GRADED (atalho PENDING → GRADED ao lançar nota;
    SUBMITTED → PENDING corrige marcação de “entregue”; GRADED → PENDING desfaz avaliação
    por engano e limpa nota/observações/`gradedAt`/`submittedAt`).
23b. O professor pode marcar a atividade como Avaliada (`evaluated=true`) ao encerrar a correção,
    mesmo com submissions ainda PENDING (ex.: zero / não entregue). Pode reabrir a correção depois.

### Insights (cruzamentos)
24. “Não entregou e estava ausente na aula de origem” = submission PENDING/não SUBMITTED + attendance ABSENT na `originLesson`.
25. “Não entregou apesar de presente” = pendente + PRESENT/LATE na origem.
26. “Atividade vencida sem correção” = `evaluated = false` e `dueDate < today` e existe submission não GRADED.
27. “Aula sem frequência” = `attendanceCompleted = false` e data ≤ hoje.
28. “Conteúdo em andamento” = status IN_PROGRESS.

---

## 8. Casos de uso (catálogo)

### Identity
- `RegisterTeacher` (opcional no MVP se houver seed do primeiro usuário)
- `Login`
- `RefreshTokens` (renova access/refresh sem novo login)
- `GetCurrentUser`
- `ChangePassword`

### Academic structure
- `CreateAcademicYear` / `ListAcademicYears` / `SetCurrentAcademicYear`
- `CreateCourse` / `UpdateCourse` / `ListCourses` / `ArchiveCourse`
- `CreateDiscipline` / `UpdateDiscipline` / `ListDisciplines`
- `LinkDisciplineToCourse` / `UnlinkDisciplineFromCourse`
- `CreateAssessmentPeriod` / `UpdateAssessmentPeriod` / `ListAssessmentPeriods` / `ReorderAssessmentPeriods`

### Students & classes
- `CreateStudent` / `UpdateStudent` / `ListStudents` / `GetStudent`
- `PreviewStudentPaste` / `CreateStudentsBatch` / `BulkCreateStudents`
- `CreateClass` (recebe `disciplineIds: string[]`) / `UpdateClass` / `ListClasses` (filtro por `disciplineId`) / `GetClass` / `ArchiveClass`
- `LinkDisciplineToClass` / `UnlinkDisciplineFromClass` / `ListClassDisciplines`
- `EnrollStudent` / `UnenrollStudent` / `ListClassStudents`
- `BulkEnrollStudents` (preparar contrato; importação CSV no futuro)

### Agenda
- `CreateAgendaNote` / `UpdateAgendaNote` / `ListAgendaNotes` / `GetAgendaNote` / `DeleteAgendaNote`
- Várias anotações por data; listagem agrupada por dia no app

### Lessons & contents
- `CreateLesson` (requer `disciplineId` vinculado à turma) / `BulkCreateLessons` (N datas, máx. 200) / `UpdateLesson` / `ListLessons` (filtro por `disciplineId`) / `GetLesson` / `DeleteLesson` (soft)
- `CreateContent` (requer `disciplineId` vinculado à turma) / `UpdateContent` / `LinkContentToLesson` / `UnlinkContentFromLesson`
- `CompleteContent` / `ReopenContent` / `ListContents` (filtro por status e `disciplineId`)

### Attendance
- `GetAttendanceSheet` (alunos da turma + status atuais)
- `SaveAttendance` (batch da aula)
- `CompleteAttendance` 
- `GetStudentAttendanceSummary`

### Activities
- `CreateActivity` (gera submissions; `disciplineIds` N:N; com aula, disciplina da aula incluída)
- `UpdateActivity` (pode alterar `disciplineIds`) / `SoftDeleteActivity`
- `CreateActivityGroups` / `AssignStudentsToGroup`
- `GradeSubmissionsBulk` (mesma nota para N entregas selecionadas, máx. 200)
- `UpdateSubmissionStatus` (PENDING ↔ SUBMITTED)
- `GradeSubmission`
- `GradeGroupShared`
- `ListActivities` (filtro por `disciplineId`) / `GetActivityBoard` (entregas da atividade)
- `MarkActivityEvaluated` / `ReopenActivityEvaluation`

### Evaluation models
- `CreateEvaluationModel` / `UpdateEvaluationModel` / `ListEvaluationModels` / `GetEvaluationModel`
- `DeactivateEvaluationModel` / `SoftDeleteEvaluationModel` (bloqueado se houver composição ativa)
- `CreateEvaluationModelItem` / `UpdateEvaluationModelItem` / `SoftDeleteEvaluationModelItem`
- `ReorderEvaluationModelItems`

### Grade compositions
- `GetGradeCompositionByContext` (sync com itens do modelo + atividades elegíveis)
- `UpsertGradeComposition` (valida pesos, unicidade de atividade, disciplina/período)
- `SoftDeleteGradeComposition`
- `CalculateGradeComposition` (normalização + média; sem nota → `null`)

### Insights & dashboard
- `GetDashboard` — agrega pendências acionáveis do professor (ano/turma opcionais)
- `GetAttentionItems` — lista unificada de ações com deep-link

### Reports
- `ReportExcessAbsences`
- `ReportAttendancePercentage`
- `ReportPendingActivities`
- `ReportUngradedActivities`
- `ReportStudentsWithoutGrade`
- `ReportContentsInProgress`
- `ReportLessonsTaught`
- `ReportLessonsWithoutAttendance`
- `ReportClassAverage`
- `ReportAverageByActivity`
- `ReportGradesByStudent`
- `ReportAttendanceByStudent`
- `ReportSubmissionStatus`
- `ReportAbsenceVsNonSubmission` (cruzamento)

Todos os relatórios aceitam filtros: `academicYearId`, `courseId`, `disciplineId`, `classId`, `assessmentPeriodId`, `from`, `to`.

---

## 9. Insights Engine (coração do Dashboard)

Componente de Application Layer: **não** é tela; é um conjunto de queries/use cases que produzem `AttentionItem`.

```ts
// Contrato conceitual (não é implementação)
AttentionItem {
  id: string
  type: AttentionType
  severity: 'high' | 'medium' | 'low'
  title: string          // "3 aulas sem frequência"
  message: string        // detalhe humano
  count: number
  filters: {...}         // para navegar à tela certa
  actionRoute: string    // deep link lógico
}
```

### Tipos MVP

| Type | Severidade sugerida | Ação |
|------|---------------------|------|
| `LESSONS_WITHOUT_ATTENDANCE` | high | Abrir chamada |
| `OVERDUE_UNGRADED_ACTIVITIES` | high | Abrir correção |
| `ACTIVITIES_AWAITING_GRADE` | high | Fila de correção |
| `CONTENTS_IN_PROGRESS` | medium | Revisar conteúdos |
| `STUDENTS_PENDING_SUBMISSION` | medium | Ver pendências |
| `ABSENT_ON_ACTIVITY_LESSON` | medium | Insight contextual |
| `EXCESS_ABSENCES` | high | Relatório / aluno |
| `ACTIVITIES_WITHOUT_SCORE` | medium | Lançar notas |

O Dashboard renderiza cards de ação ordenados por severidade + recência, não um mosaic de KPIs vazios.

---

## 10. Organização do backend

```
backend/
  prisma/
    schema.prisma
    migrations/
    seed.ts
  src/
    main.ts
    app.ts
    config/
    shared/
      domain/          # Result, DomainError, Ids
      infra/           # prisma client, logger
      http/            # error handler, middleware base
    modules/
      identity/
        domain/
        application/
        infrastructure/
        presentation/
      academic/
      students/
      classes/
      lessons/
      contents/
      attendance/
      activities/
      insights/
      reports/
    di/                # composition root (DI)
  tests/
  swagger/
```

### Convenções
- 1 Use Case = 1 arquivo = 1 responsabilidade.
- Controllers só adaptam HTTP ↔ Use Case.
- Interfaces de repositório no `application` ou `domain`; implementação Prisma em `infrastructure`.
- DI no composition root (sem service locator escondido).
- Toda rota autenticada passa por `authMiddleware` + contexto `teacherId`.

---

## 11. Organização do frontend (Flutter)

```
frontend/lib/
  main.dart
  app.dart
  core/
    theme/
    router/
    network/          # Dio + interceptors
    errors/
    widgets/          # AppScaffold, EmptyState, ErrorState, Loading
  domain/
    entities/
    repositories/     # abstrações
  data/
    datasources/      # API
    repositories/     # impl
    dto/
  application/        # use cases locais (opcional) / services de orquestração
  presentation/
    providers/        # Riverpod
    screens/
      auth/
      dashboard/
      academic/
      classes/
      lessons/
      attendance/
      contents/
      activities/
      students/
      reports/
      settings/
    widgets/          # feature widgets reutilizáveis
```

Fluxo obrigatório:

`Screen → Provider (Riverpod) → Repository/UseCase → Datasource → API`

Estados padrão em toda tela: **Loading · Error · Empty · Success**.  
Temas: **Light e Dark**.

---

## 12. Estrutura das APIs (REST)

Base: `/api/v1`

### Auth
- `POST /auth/login` · `POST /auth/refresh` · `GET /auth/me`
- `POST /auth/register` (se habilitado)
- `GET /auth/me`
- `PATCH /auth/password`

### Academic
- `/academic-years`
- `/courses`
- `/disciplines`
- `/courses/:id/disciplines`
- `/assessment-periods`

### Students & classes
- `/students`
- `/classes`
- `/classes/:id/enrollments`
- `/classes/:id/enrollments/bulk`
- `/classes/:classId/disciplines`

### Lessons, contents, attendance
- `/classes/:classId/lessons`
- `/classes/:classId/contents`
- `/lessons/:id/contents`
- `/lessons/:id/attendance` (GET sheet, PUT batch)

### Activities
- `/classes/:classId/activities`
- `/activities/:id`
- `/activities/:id/groups`
- `/activities/:id/submissions`
- `/submissions/:id/grade`

### Insights & reports
- `GET /dashboard`
- `GET /attention-items`
- `GET /reports/:reportType`

### Padrões de resposta
- Sucesso: `{ data, meta? }`
- Erro: `{ error: { code, message, details? } }`
- Paginação: `page`, `pageSize`, `total`
- Códigos: 200/201/204/400/401/403/404/409/422/429/500
- Rate limit: desligado em `development`; em produção `RATE_LIMIT_MAX` (default 2000/15min);
  login/register/refresh com limite próprio (30/15min).
- Nunca expor stacktrace.

Documentação: **Swagger/OpenAPI** gerado/mantido por módulo.

---

## 13. Autenticação e controle de acesso

### MVP
- Login e-mail/senha → JWT access + refresh (secure storage no Flutter).
- `POST /auth/refresh` renova o par; o cliente faz retry silencioso em `401`.
- Payload: `{ sub: userId, role: 'PROFESSOR' }`.
- `teacherId` de negócio = `sub` no MVP (1 user = 1 professor).

### Isolamento
- Middleware autentica e injeta `AuthContext`.
- Repositórios recebem `teacherId` obrigatório.
- Testes de segurança: tentativa de acesso a ID de outro professor → 404 (não 403), para não vazar existência.

### Preparação para papéis futuros
- Coluna/enum `role` já existe.
- Interface `AuthorizationPolicy.can(action, resource, ctx)`.
- MVP: policy permite tudo ao dono PROFESSOR nos próprios recursos.
- Futuro: COORDINATOR/ADMIN com escopos sem alterar entidades de negócio.

### Segurança (rules do projeto)
- bcrypt, Helmet, CORS, rate limit, sanitização, validação Zod.
- Senha nunca em texto puro; logs sem PII sensível.

---

## 14. Estrutura do banco de dados

### Diretrizes
- PostgreSQL + Prisma migrations + seeds.
- Toda FK indexada.
- `teacher_id` indexado em todas as tabelas de negócio.
- Unique constraints de negócio compostas com `teacher_id` quando fizer sentido.
- Soft delete (`deleted_at`) em entidades históricas.
- Timestamps `created_at` / `updated_at`.
- Normalização 3NF; denormalização só com motivo (ex.: `attendance_completed` em `lessons` para Insights).

### Tabelas principais

`users`, `academic_years`, `courses`, `disciplines`, `course_disciplines`, `assessment_periods`, `classes`, `students`, `enrollments`, `lessons`, `contents`, `lesson_contents`, `attendances`, `activities`, `activity_groups`, `activity_group_members`, `submissions`

### Índices críticos para Insights/Relatórios
- `lessons (teacher_id, attendance_completed, date)`
- `contents (teacher_id, status, class_id)`
- `activities (teacher_id, due_date, class_id)`
- `submissions (activity_id, status)`
- `attendances (lesson_id, status)` / `(student_id, status)`
- `enrollments (class_id, status)`

### Seed inicial
- Usuário professor demo
- Ano letivo atual
- 1 curso, 1 disciplina, 1 turma, alguns alunos
- Períodos (1º/2º bimestre)
- Aulas/atividades de exemplo com pendências — para o Dashboard já nascer útil

---

## 15. Principais telas e navegação

### Mapa de navegação

```
Login
  └─ Shell (nav)
       ├─ Dashboard          ★ home
       ├─ Minha Rotina       (atalhos do dia)
       ├─ Turmas
       │    └─ Turma Detail
       │         ├─ Aulas
       │         ├─ Frequência (por aula)
       │         ├─ Conteúdos
       │         ├─ Atividades
       │         └─ Alunos / Notas
       ├─ Alunos
       ├─ Relatórios
       └─ Configurações
            ├─ Anos letivos
            ├─ Cursos & Disciplinas
            ├─ Períodos avaliativos
            └─ Conta
```

### Telas MVP (prioridade)

1. **Login**
2. **Dashboard** — attention items + resumo do dia
3. **Lista de Turmas** — filtro por ano letivo
4. **Detalhe da Turma** — hub com contadores de pendência; edição de nome/turno; disciplinas; arquivar
5. **Lista/Agenda de Aulas** — criação unitária ou em lote (período + dias da semana, ou dias avulsos no calendário)
6. **Chamada (Frequência)** — grid rápido Presente/Ausente/Atrasado
7. **Conteúdos** — em andamento / concluídos; vincular a aulas
8. **Atividades** — board de entregas; correção rápida
9. **Lançamento de Nota** — individual ou grupo (shared/individual)
10. **Alunos** — perfil com faltas, médias, pendências
11. **Relatórios** — seletor + filtros + resultado exportável (export real no futuro)
12. **Configurações acadêmicas**

### Fluxos de produtividade (UX)

**Manhã do professor (happy path):**
1. Abre app → Dashboard
2. Toca “3 aulas sem frequência” → já na chamada
3. Marca presença em lote → salva
4. Volta ao Dashboard → próxima pendência (corrigir atividades)

**Após a aula:**
1. Abre aula do dia
2. Registra conteúdo (reutiliza conteúdo em andamento ou cria novo)
3. Cria atividade (se houver) com due date
4. Sistema gera entregas PENDING automaticamente

Meta de interação: **frequência de uma turma ≤ 1 minuto**.

---

## 16. Componentes reutilizáveis (Flutter)

| Componente | Uso |
|------------|-----|
| `AppScaffold` | Shell com nav + seletor de ano letivo |
| `YearSelector` | Contexto global do ano |
| `AttentionCard` | Item do Dashboard |
| `PendingBadge` | Contador em turmas/aulas |
| `StudentAvatarList` | Listas compactas |
| `AttendanceToggle` | PRESENT/ABSENT/LATE |
| `ScoreField` | Nota com maxScore |
| `StatusChip` | Pendente/Entregue/Corrigida etc. |
| `FilterBar` | Ano/curso/disciplina/turma/período |
| `EmptyState` / `ErrorState` / `LoadingState` | Estados padrão |
| `ConfirmDialog` / `AppSnackbar` | Feedback |
| `SectionHeader` | Hierarquia visual limpa |

Evitar telas “dashboardizadas” demais fora do Dashboard. Nas demais, **uma tarefa por tela**.

---

## 17. Relatórios

Cada relatório é um Use Case de leitura + endpoint + tela de resultado com os mesmos filtros.

Prioridade de implementação:

**P0 (MVP)**  
- Aulas sem frequência  
- Atividades aguardando correção / vencidas sem correção  
- Conteúdos em andamento  
- Alunos com excesso de faltas  
- Pendências de entrega  
- Relação faltas × não entrega  

**P1**  
- Percentual de presença  
- Média da turma / por atividade  
- Notas por aluno  
- Frequência por aluno  
- Aulas ministradas  

Exportação (CSV/PDF) fica como porta `ReportExporter` — implementação futura sem mudar Use Cases.

---

## 18. Oportunidades de automação (MVP-friendly)

| Automação | Benefício | Complexidade |
|-----------|-----------|--------------|
| Gerar submissions ao criar atividade | Zero clique extra | Baixa |
| Sugerir “aluno ausente na aplicação” no board | Contexto imediato | Baixa |
| Marcar aula sem frequência automaticamente no Dashboard | Evita esquecimento | Baixa |
| Ao concluir chamada, oferecer “registrar conteúdo” | Fluxo contínuo | Baixa |
| Ao criar aula, sugerir conteúdos IN_PROGRESS da turma | Continuidade didática | Média |
| Default `maxScore = 100` | Menos fricção | Trivial |
| Deep link de cada AttentionItem | Menos navegação | Baixa |
| Lembrete local (futuro): aulas de hoje sem chamada | Proativo | Média (mobile) |

Evitar automações que alterem nota/frequência sem confirmação explícita do professor.

---

## 19. Preparação para o futuro (sem implementar agora)

| Capacidade futura | Gancho arquitetural já previsto |
|-------------------|----------------------------------|
| Múltiplos professores | `teacherId` + auth multi-user |
| Admin / Coordenador / Secretaria | `UserRole` + `AuthorizationPolicy` |
| Compartilhamento de turmas | Tabela futura `class_shares`; leitura via policy |
| Calendário institucional | `AssessmentPeriod.classId` opcional + origem INSTITUTIONAL |
| Notificações | Porta `NotificationPublisher` nos Use Cases relevantes |
| App mobile | Flutter já é a UI; API stateless |
| Sync nuvem | API como source of truth; conflitos via `updated_at` |
| Importação de alunos | `BulkEnrollStudents` + `StudentImporter` |
| Sistemas acadêmicos | Adaptadores em Infrastructure (`AcademicSystemGateway`) |
| Exportação relatórios | `ReportExporter` |
| Google Classroom / Teams | Portas `ExternalClassroomGateway` |

Regra: **Application depende de interfaces; Infrastructure implementa adaptadores**. Novas integrações = novas classes, não refactor de domínio.

---

## 20. Melhorias de produto (baixo custo, alto valor)

1. **Seletor global de Ano Letivo** no shell — evita filtrar em toda tela.  
2. **Modo “Aula de hoje”** — atalho que abre a próxima aula do dia com chamada + conteúdo.  
3. **Correção rápida** — lista só submissions não corrigidas, teclado numérico, próximo aluno automático.  
4. **Presença em 3 toques por aluno** (Presente padrão; swipe/tap para Ausente/Atrasado).  
5. **Insight narrativo** no Dashboard (“João faltou na aula da Lista 3 e não entregou”) — 3 exemplos/dia bastam.  
6. **Arquivar turma** em vez de excluir — histórico intacto.  
7. **Duplicar atividade** para outra turma/ano — produtividade em semestres parecidos (P1).

---

## 21. Estratégia de testes

| Camada | Foco |
|--------|------|
| Domain | Invariantes (nota, status, horários) |
| Use Cases | Regras + ownership + cruzamentos Insights |
| Repositories | Constraints, filtros por `teacherId` |
| Controllers | Status HTTP, validação Zod |
| Flutter Providers | Estados loading/error/empty |
| Widgets chave | Dashboard cards, AttendanceToggle, ScoreField |

Mocks nas bordas; preferir testes de Use Case como rede de segurança principal.

---

## 22. Variáveis de ambiente (iniciais)

```
NODE_ENV=
PORT=
DATABASE_URL=
JWT_SECRET=
JWT_EXPIRES_IN=
REFRESH_TOKEN_SECRET=
REFRESH_TOKEN_EXPIRES_IN=
CORS_ORIGIN=
RATE_LIMIT_WINDOW_MS=
RATE_LIMIT_MAX=
```

Frontend: `API_BASE_URL` (flavors dev/prod).

---

## 23. Ordem recomendada de implementação

1. ~~Foundation (monorepo folders, lint, Prisma, auth JWT)~~ ✅
2. ~~Academic structure (ano, curso, disciplina, períodos)~~ ✅
3. ~~Students + Classes + Enrollments~~ ✅
4. ~~Lessons~~ ✅
5. ~~Attendance (+ flag completed)~~ ✅
6. ~~Contents + vínculos~~ ✅
7. ~~Activities + submissions + grading (individual)~~ ✅
8. ~~Group activities~~ ✅
9. ~~Insights Engine + Dashboard~~ ✅
10. ~~Reports P0 (+ P1)~~ ✅
11. ~~Frontend Flutter (shell + Dashboard + fluxos P0)~~ ✅
12. ~~Agenda (diário por dia + item no shell)~~ ✅
13. Evoluções futuras: exportação CSV/PDF, notificações, importação em massa, integrações externas

Cada fatia vertical deve entregar valor usável (não “só CRUD isolado” sem aparecer no Dashboard quando fizer sentido).

---

## 24. Critérios de aceite arquiteturais

- [ ] Nenhuma regra de negócio em Controllers ou Widgets
- [ ] Prisma apenas em Infrastructure
- [ ] Todo Use Case de escrita valida ownership
- [ ] Dashboard consome Insights, não queries ad hoc na UI
- [ ] Soft delete / archive preserva histórico
- [ ] Swagger atualizado por endpoint
- [ ] Testes de isolamento multi-professor
- [ ] Light/Dark + estados Loading/Error/Empty/Success

---

## 25. Glossário

| Termo UI (PT) | Termo técnico |
|---------------|---------------|
| Professor / Usuário | User |
| Ano letivo | AcademicYear |
| Curso | Course |
| Disciplina | Discipline |
| Período avaliativo | AssessmentPeriod |
| Turma | Class |
| Vínculo turma-disciplina | ClassDiscipline |
| Aluno | Student |
| Matrícula | Enrollment |
| Aula | Lesson |
| Conteúdo | Content |
| Frequência | Attendance |
| Atividade | Activity |
| Entrega | Submission |
| Modelo avaliativo | EvaluationModel |
| Item do modelo | EvaluationModelItem |
| Composição da nota | GradeComposition |
| Pendência / Alerta | AttentionItem |

---

**Próximo passo sugerido:** validar este documento (especialmente Período Avaliativo, agregados e prioridade do Dashboard) e, em seguida, gerar o **modelo Prisma + contratos OpenAPI iniciais** sem ainda implementar regras de tela.
