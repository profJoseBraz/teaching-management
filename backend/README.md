# Gestão Docente — Backend API

API REST em Clean Architecture (Express + TypeScript + Prisma + PostgreSQL).

## Quick start

```bash
# 1) Configure .env (veja .env.example)
# 2) Banco pronto (docker compose ou scripts/setup-db.sql na raiz)

npm install
npx prisma migrate deploy
npx prisma db seed
npm run dev
```

- Swagger: http://localhost:3333/api/docs  
- Health: http://localhost:3333/api/v1/health  

Demo: `professor@gestao.docente` / `Professor@123`

## Módulos

`identity` · `academic` · `students` · `classes` · `lessons` · `contents` · `attendance` · `activities` · `insights` · `reports`

## Testes

```bash
npm test
npm run lint
```
