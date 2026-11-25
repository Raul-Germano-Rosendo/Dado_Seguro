# 03 — Mostrar Dockerfile e Docker Compose na AWS

## Objetivo

Exibir os arquivos que empacotam e executam a API e o PostgreSQL, e explicar onde os dados persistem.

## Na Backend 1

Conecte por SSH autorizado e mostre o Dockerfile:

```bash
sudo sed -n '1,160p' /opt/dado-seguro/backend/Dockerfile
```

O Dockerfile usa Node.js Alpine, instala dependências de produção, copia o build compilado, cria o diretório de uploads, roda sem root e inicia `dist/server.js`.

Mostre o Compose base do PostgreSQL e o overlay da aplicação:

```bash
sudo sed -n '1,200p' /opt/dado-seguro/compose.yaml
sudo sed -n '1,240p' /opt/dado-seguro/deploy/compose.application.yaml
```

Explique:

- `compose.yaml` define PostgreSQL 16, segredos montados como arquivos e volume persistente do banco.
- `compose.application.yaml` monta o SQL em `/docker-entrypoint-initdb.d:ro`, cria a API e monta `uploads_data`.
- PostgreSQL não publica porta no host; API publica `3000` somente em `127.0.0.1`.
- O Nginx backend encaminha `/api` à API local.

Confira a configuração combinada sem revelar o conteúdo dos segredos:

```bash
sudo docker compose \
  -f /opt/dado-seguro/compose.yaml \
  -f /opt/dado-seguro/deploy/compose.application.yaml config --quiet
sudo docker compose \
  -f /opt/dado-seguro/compose.yaml \
  -f /opt/dado-seguro/deploy/compose.application.yaml ps
```

Para mostrar os volumes montados no PostgreSQL:

```bash
sudo docker inspect dado-seguro-postgres \
  --format '{{range .Mounts}}{{println .Source "=>" .Destination "rw=" .RW}}{{end}}'
```

Não execute `docker inspect` completo dos containers nem leia arquivos `.db_password`, `.admin_password` ou `.session_secret` durante a prova.
