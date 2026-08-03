# Banco de dados

## Modelo

Schema Prisma: `backend/prisma/schema.prisma`  
Migration inicial: `backend/prisma/migrations/20260803180000_init/`

Todas as tabelas de negócio possuem `teacher_id` (exceto junções puras como `lesson_contents` e `activity_group_members`, subordinadas a agregados já isolados).

## Subir o banco

### Opção A — Docker Compose (recomendado)

```bash
docker compose up -d
```

Usa:

```
postgresql://gestao:gestao@localhost:5432/gestao_docente?schema=public
```

### Opção B — PostgreSQL local (Windows)

1. Execute o script (informe a senha do superuser `postgres` quando pedido):

```powershell
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -h localhost -f scripts/setup-db.sql
```

Ou manualmente no `psql`:

```sql
CREATE USER gestao WITH PASSWORD 'gestao';
CREATE DATABASE gestao_docente OWNER gestao;
```

2. Confirme `backend/.env` → `DATABASE_URL=postgresql://gestao:gestao@localhost:5432/gestao_docente?schema=public`

3. Rode:

```bash
cd backend
npx prisma migrate deploy
npx prisma db seed
```

Se preferir usar outro usuário/senha do PostgreSQL, apenas atualize a `DATABASE_URL` — o schema Prisma é o mesmo.

## Seed

Cria professor demo, ano 2026, curso, disciplina, turma, alunos, aulas, conteúdo em andamento e atividade com entregas pendentes — suficiente para exercitar o Dashboard depois.

| Campo | Valor |
|-------|-------|
| E-mail | `professor@gestao.docente` |
| Senha | `Professor@123` |
