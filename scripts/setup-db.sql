-- Run as PostgreSQL superuser:
--   "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -h localhost -f scripts/setup-db.sql

DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'gestao') THEN
    CREATE ROLE gestao LOGIN PASSWORD 'gestao';
  ELSE
    ALTER ROLE gestao WITH LOGIN PASSWORD 'gestao';
  END IF;
END
$$;

SELECT 'CREATE DATABASE gestao_docente OWNER gestao'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'gestao_docente')\gexec

GRANT ALL PRIVILEGES ON DATABASE gestao_docente TO gestao;
