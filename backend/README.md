# API do Dado Seguro

API Node.js/TypeScript que implementa o contrato usado por `frontend/src/services/api.ts`. PostgreSQL armazena usuários, sessões, metadados de arquivos e auditoria; o conteúdo dos arquivos fica em um volume Docker.

## Rotas

| Método | Rota | Acesso | Descrição |
|---|---|---|---|
| `POST` | `/auth/login` | Público, com limite de tentativas | Cria sessão HTTP-only |
| `POST` | `/auth/logout` | Sessão válida | Encerra sessão |
| `GET` | `/auth/me` | Sessão válida | Retorna usuário atual |
| `GET` | `/files` | Sessão válida | Lista arquivos autorizados |
| `POST` | `/files` | Sessão válida | Envia um arquivo de até 25 MB |
| `GET` | `/files/:id/download` | Sessão e permissão | Baixa como anexo |
| `DELETE` | `/files/:id` | Proprietário ou admin | Exclui conteúdo e metadado |
| `GET` | `/audit` | Admin | Lista até 100 eventos recentes |
| `GET` | `/healthz` | Interno | Health check com consulta ao banco |

## Autorização e dados

- O primeiro administrador (`admin`) é criado na inicialização. A senha é lida do secret `/run/secrets/admin_password`; ela nunca é incluída no código ou no Git.
- Senhas são armazenadas como hash bcrypt. A sessão fica no PostgreSQL e o cookie é `HttpOnly`, `SameSite=Lax` e expira após oito horas.
- Administradores veem todos os arquivos. Usuários comuns veriam os próprios arquivos e os marcados como `equipe`; não há rota para criar contas nesta primeira versão.
- Conteúdo é guardado com nome interno UUID; o nome original fica como metadado e é enviado ao cliente somente como download.
- `encrypted` permanece `false`: esta versão não implementa criptografia de conteúdo. O volume está local na instância; não use documentos reais pela URL HTTP de demonstração.

O esquema das tabelas está em [`db/init/001_initial_schema.sql`](db/init/001_initial_schema.sql). O Compose monta essa pasta, somente leitura, em `/docker-entrypoint-initdb.d` no PostgreSQL. O script de implantação aplica o SQL de forma idempotente antes de iniciar a API; assim, também funciona quando o volume do banco já existia. `CREATE TABLE IF NOT EXISTS` e `CREATE INDEX IF NOT EXISTS` preservam os registros ao repetir a etapa.

## Executar no ambiente do projeto

Compile o TypeScript antes de construir a imagem, para manter o uso de memória da instância pequena:

```bash
npm ci
npm run build
```

Depois copie `backend/` (incluindo `dist/`) para `/opt/dado-seguro/backend` e use os dois arquivos Compose, com o Compose base apontando para o serviço `db`:

```bash
sudo docker compose \
  -f /opt/dado-seguro/compose.yaml \
  -f /opt/dado-seguro/deploy/compose.application.yaml \
  up -d --build --wait
```

O banco é alcançado pelo host interno `db:5432`. O processo API publica `3000` somente em loopback e usa secrets montados; o Nginx faz o encaminhamento para `/api`. Para conferir as tabelas no PostgreSQL:

```bash
sudo docker compose \
  -f /opt/dado-seguro/compose.yaml \
  -f /opt/dado-seguro/deploy/compose.application.yaml \
  exec -T db psql -U dadoseguro_app -d dadoseguro -c '\dt'
```
