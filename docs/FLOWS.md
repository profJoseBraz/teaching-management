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

## Refresh token (renovação silenciosa)

```mermaid
sequenceDiagram
  participant App as Flutter
  participant Int as AuthInterceptor
  participant API as Express
  participant UC as RefreshTokensUseCase

  App->>API: GET /recurso (access expirado)
  API-->>Int: 401
  Int->>API: POST /auth/refresh { refreshToken }
  API->>UC: verify + issueTokens
  UC-->>API: tokens
  API-->>Int: 200 { tokens }
  Int->>API: retry GET /recurso (novo access)
  API-->>App: 200
  Note over Int: Se refresh falhar → limpa tokens e vai ao login
```

## Agenda (anotações por data)

```mermaid
sequenceDiagram
  participant App as Flutter
  participant API as Express
  participant UC as CreateAgendaNoteUseCase
  participant DB as PostgreSQL

  App->>API: POST /agenda-notes { date, content }
  API->>UC: execute(teacherId, date, content)
  UC->>DB: create
  UC-->>API: AgendaNote
  API-->>App: 201 { data }
```

No app: menu **Agenda** → filtros **Pendentes / Concluídas / Todas**, texto e data →
cada **linha é uma anotação distinta** (várias no mesmo dia). **Nova anotação** cria
sempre um registro novo (data padrão hoje, alterável). Checkbox conclui; exclusão remove só aquela linha.

## Período avaliativo (contexto global)

No AppBar: seletor de **ano letivo** + seletor de **período** (ex.: 1º Trimestre).
Aulas, frequência (via aulas), conteúdos e atividades listam e criam no período efetivo.

```mermaid
flowchart LR
  Config[Config: períodos do ano] --> AppBar[Seletor período]
  AppBar --> Lists[GET ?assessmentPeriodId=]
  AppBar --> Create[POST assessmentPeriodId]
  Lists --> Lessons[Aulas / Frequência]
  Lists --> Contents[Conteúdos]
  Lists --> Activities[Atividades]
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
