# Variáveis de ambiente

## Backend (`backend/.env`)

| Variável | Obrigatória | Default | Descrição |
|----------|-------------|---------|-----------|
| `NODE_ENV` | não | `development` | Ambiente |
| `PORT` | não | `3333` | Porta HTTP |
| `DATABASE_URL` | sim | — | Connection string PostgreSQL |
| `JWT_SECRET` | sim | — | Segredo do access token (mín. 32 chars) |
| `JWT_EXPIRES_IN` | não | `15m` | Expiração do access token |
| `REFRESH_TOKEN_SECRET` | sim | — | Segredo do refresh token (mín. 32 chars) |
| `REFRESH_TOKEN_EXPIRES_IN` | não | `7d` | Expiração do refresh token |
| `CORS_ORIGIN` | não | `*` | Origens permitidas (`*` ou lista CSV) |
| `RATE_LIMIT_WINDOW_MS` | não | `900000` | Janela do rate limit da API (ms). Em `development` o limite geral fica desligado. |
| `RATE_LIMIT_MAX` | não | `2000` | Máx. requests por janela na API (produção). Login/register têm limite próprio (30/15min). |

Modelo: `backend/.env.example`

## Docker Compose

| Serviço | Host | Credenciais |
|---------|------|-------------|
| PostgreSQL | `localhost:5432` | user/pass/db: `gestao` / `gestao` / `gestao_docente` |

```
DATABASE_URL=postgresql://gestao:gestao@localhost:5432/gestao_docente?schema=public
```

## Frontend (futuro)

| Variável | Descrição |
|----------|-----------|
| `API_BASE_URL` | URL da API (ex.: `http://localhost:3333/api/v1`) |
