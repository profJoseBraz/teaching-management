# Gestão Docente

Assistente da rotina do professor: centraliza turmas, aulas, frequência, conteúdos, atividades e pendências — com um Dashboard que prioriza ações.

> Especificação: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)

## Stack

| Camada | Tecnologia |
|--------|------------|
| Frontend | Flutter + Riverpod + Dio + go_router + Material 3 |
| Backend | Node.js + Express + TypeScript |
| Banco | PostgreSQL + Prisma |
| Auth | JWT + bcrypt |
| Docs API | Swagger / OpenAPI |

## Estrutura

```
TeachingManagement/
├── backend/          # API Clean Architecture (completa)
├── frontend/         # App Flutter MVP
├── docs/             # Arquitetura, API, DB, fluxos
├── scripts/          # setup-db.sql
└── .cursor/          # Rules, agents e skills
```

## Pré-requisitos

- Node.js 20+
- PostgreSQL 16+ (serviço local ou Docker)
- Flutter 3.35+ / Dart 3.12+

## 1. Banco de dados

### Docker (se disponível)

```bash
docker compose up -d
```

### PostgreSQL local

1. Crie usuário/banco (como superuser):

```bash
# Windows — ajuste o caminho do psql se necessário
"C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -h localhost -f scripts/setup-db.sql
```

2. Confirme `backend/.env`:

```
DATABASE_URL=postgresql://gestao:gestao@localhost:5432/gestao_docente?schema=public
```

Detalhes: [`docs/DATABASE.md`](docs/DATABASE.md)

## 2. Backend

```bash
cd backend
cp .env.example .env   # se ainda não existir
npm install
npx prisma migrate deploy
npx prisma db seed
npm run dev
```

| Recurso | URL |
|---------|-----|
| API | http://localhost:3333/api/v1 |
| Swagger | http://localhost:3333/api/docs |
| Health | http://localhost:3333/api/v1/health |

### Usuário demo (seed)

| Campo | Valor |
|-------|-------|
| E-mail | `professor@gestao.docente` |
| Senha | `Professor@123` |

## 3. Frontend

```bash
cd frontend
flutter pub get
flutter run -d chrome
# ou: flutter run -d windows
```

No emulador Android, altere a base URL em `frontend/lib/core/network/api_client.dart` para `http://10.0.2.2:3333/api/v1`.

Guia completo: [`frontend/README.md`](frontend/README.md)

## Módulos implementados

### Backend
- Auth (register / login / me)
- Academic (anos, cursos, disciplinas, períodos avaliativos)
- Students + Classes + Enrollments
- Agenda (anotações distintas, agrupadas por data)
- Lessons + Contents + Attendance
- Activities + Submissions + Groups + grading (descrição Markdown, tag, N disciplinas por atividade)
- Evaluation Models (catálogo) + Grade Compositions (turma/disciplina/período)
- Insights Engine + Dashboard
- Reports (P0 + P1)

### Frontend
- Login + shell responsivo (AppBar: ano letivo + período avaliativo)
- Dashboard com AttentionItems
- Turmas (hub: aulas, frequência, conteúdos, atividades e alunos filtrados pelo período selecionado)
- Composição da Nota (por disciplina + período; modelos em Config)
- Alunos, Agenda (anotações), Relatórios, Configurações (CRUD acadêmico + modelos avaliativos + tema)

## Arquitetura

```
Presentation → Application → Domain ← Infrastructure
```

- Controllers / Screens sem regra de negócio
- Use Cases centralizam regras
- Prisma / Dio só na Infrastructure / Data
- Isolamento por `teacherId` em todo dado de negócio

## Documentação

| Documento | Conteúdo |
|-----------|----------|
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Arquitetura e domínio |
| [`docs/API.md`](docs/API.md) | Contratos REST |
| [`docs/DATABASE.md`](docs/DATABASE.md) | Banco e seed |
| [`docs/ENVIRONMENT.md`](docs/ENVIRONMENT.md) | Variáveis de ambiente |
| [`docs/FLOWS.md`](docs/FLOWS.md) | Fluxos |
| Swagger UI | Contrato interativo |

## Scripts úteis

```bash
# Backend
cd backend && npm run dev
cd backend && npm test
cd backend && npm run prisma:studio

# Frontend
cd frontend && flutter analyze
cd frontend && flutter test
```
