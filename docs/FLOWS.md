# Fluxos principais

## Autenticação

```mermaid
sequenceDiagram
  participant App as Flutter
  participant API as Express
  participant UC as LoginUseCase
  participant DB as PostgreSQL

  App->>API: POST /auth/login
  API->>UC: execute(email, password)
  UC->>DB: findByEmail
  UC->>UC: bcrypt.compare
  UC-->>API: user + tokens
  API-->>App: 200 { data }
```

## Ownership (todas as features futuras)

```mermaid
flowchart LR
  JWT[JWT sub] --> Ctx[AuthContext.teacherId]
  Ctx --> UC[Use Case]
  UC --> Repo[Repository filter teacherId]
  Repo --> DB[(PostgreSQL)]
```

## Dashboard (previsto)

```mermaid
flowchart TD
  Open[Abrir app] --> Dash[GET /dashboard]
  Dash --> Insights[Insights Engine]
  Insights --> Items[AttentionItems]
  Items --> Action[Deep link: chamada / correção / conteúdo]
  Action --> Done[Pendência resolvida]
  Done --> Dash
```

## Nota em lote (seleção de alunos)

```mermaid
sequenceDiagram
  participant App as Flutter
  participant API as Express
  participant UC as GradeSubmissionsBulk
  participant DB as PostgreSQL

  App->>API: POST /activities/{id}/submissions/grade-bulk
  Note over App,API: { submissionIds[], score, observations? }
  API->>UC: execute
  UC->>DB: updateMany GRADED + score
  UC-->>API: Submission[]
  API-->>App: 200 { data }
```

## Criar atividade (múltiplas disciplinas)

```mermaid
sequenceDiagram
  participant App as Flutter
  participant API as Express
  participant UC as CreateActivityUseCase
  participant CD as ClassDisciplineGateway
  participant DB as PostgreSQL

  App->>API: POST /classes/{id}/activities { disciplineIds[], ... }
  API->>UC: execute
  UC->>CD: areAllLinked(disciplineIds)
  UC->>DB: Activity + ActivityDiscipline[]
  UC->>DB: Submission PENDING (alunos ativos)
  UC-->>API: Activity { disciplineIds }
  API-->>App: 201 { data }
```
