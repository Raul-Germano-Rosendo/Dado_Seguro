# 04 — Mostrar como as tabelas PostgreSQL são criadas

## Arquivo de definição

O schema está versionado em:

```text
backend/db/init/001_initial_schema.sql
```

No container PostgreSQL, a pasta é montada como `/docker-entrypoint-initdb.d` em modo somente leitura. O script de deploy aplica o arquivo antes de iniciar a API. Ele usa `CREATE TABLE IF NOT EXISTS` e `CREATE INDEX IF NOT EXISTS`, portanto pode ser executado novamente sem apagar os registros existentes.

## Mostrar as tabelas

Na Backend 1:

```bash
sudo docker compose \
  -f /opt/dado-seguro/compose.yaml \
  -f /opt/dado-seguro/deploy/compose.application.yaml \
  exec -T db psql -U dadoseguro_app -d dadoseguro -c '\dt'
```

Resultado esperado: `app_users`, `stored_files`, `audit_entries` e `app_sessions`.

Mostre a definição de uma tabela:

```bash
sudo docker compose \
  -f /opt/dado-seguro/compose.yaml \
  -f /opt/dado-seguro/deploy/compose.application.yaml \
  exec -T db psql -U dadoseguro_app -d dadoseguro -c '\d stored_files'
```

Para conferir o registro enviado durante a prova, use a consulta em [Persistência](02-persistencia.md).

## Explicação curta

O PostgreSQL oficial executa scripts de `/docker-entrypoint-initdb.d` quando inicializa um diretório de dados vazio. Como a instância de demonstração já tinha um volume, `enable-api.sh` também aplica o SQL explicitamente em cada implantação. O schema não fica escondido dentro do código TypeScript e pode ser revisado no Git.
