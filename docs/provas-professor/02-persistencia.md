# 02 — Comprovar persistência dos dados

## Objetivo

Mostrar que metadados são gravados no PostgreSQL e que banco e arquivos continuam disponíveis após parar e iniciar os containers sem apagar os volumes.

## Criar um registro de demonstração

1. Conecte a VPN e abra `http://172.31.30.175`.
2. Entre com a conta de demonstração autorizada. Obtenha a senha diretamente no host por um administrador; ela não está no Git.
3. Envie um arquivo fictício pequeno, por exemplo `prova-persistencia.txt`.
4. Confirme que o arquivo aparece na lista e anote o nome para localizá-lo depois da reinicialização.

## Verificar metadados no banco

Na Backend 1 (`98.88.6.219`), execute:

```bash
sudo docker compose \
  -f /opt/dado-seguro/compose.yaml \
  -f /opt/dado-seguro/deploy/compose.application.yaml \
  exec -T db psql -U dadoseguro_app -d dadoseguro \
  -c "SELECT original_name, size_bytes, access, uploaded_at FROM stored_files ORDER BY uploaded_at DESC LIMIT 5;"
```

O nome de demonstração deve aparecer na consulta. O PostgreSQL guarda os metadados; o conteúdo do arquivo fica no volume `uploads_data` da API.

## Parar e iniciar sem apagar dados

```bash
sudo docker compose \
  -f /opt/dado-seguro/compose.yaml \
  -f /opt/dado-seguro/deploy/compose.application.yaml stop

sudo docker compose \
  -f /opt/dado-seguro/compose.yaml \
  -f /opt/dado-seguro/deploy/compose.application.yaml up -d --wait
```

Confira os serviços e a API:

```bash
sudo docker compose \
  -f /opt/dado-seguro/compose.yaml \
  -f /opt/dado-seguro/deploy/compose.application.yaml ps
curl -fsS http://127.0.0.1:3000/healthz
```

Repita a consulta SQL e abra a aplicação pela VPN. O mesmo arquivo deve continuar listado e deve baixar corretamente.

## O que explicar

- PostgreSQL usa o volume nomeado `postgres_data`.
- Os arquivos enviados pela aplicação usam o volume nomeado `uploads_data`.
- `docker compose stop` e `up` mantêm os volumes.
- `docker compose down -v` apagaria os volumes e não deve ser usado na apresentação.

## Evidência já executada

Em 24/11/2026, API e banco foram parados e iniciados com `stop` e `up -d --wait`, sem `-v`. A contagem de usuários no banco ficou `1` antes e depois, e a API retornou `{"status":"ok"}`. A prova de upload/baixar o mesmo arquivo pode ser repetida ao vivo com um arquivo fictício.
