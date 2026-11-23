# 10. Deploy com Docker, API e PostgreSQL

## Arquitetura implantada

A stack da demonstração usa uma instância backend Ubuntu com Docker Compose para API Node.js/TypeScript e PostgreSQL 16. O Nginx backend encaminha requisições para a API em `127.0.0.1:3000`; a porta PostgreSQL 5432 não é publicada no host. Na instância frontend, Nginx serve o build React/Vite e encaminha `/api/` para a backend. A interface e os dados são persistidos separadamente: metadados no PostgreSQL e conteúdo dos arquivos em volume Docker local.

O procedimento base para preparar o host e o banco é [`deploy/setup-backend.sh`](../deploy/setup-backend.sh). [`deploy/compose.application.yaml`](../deploy/compose.application.yaml) adiciona a API à composição existente e [`deploy/enable-api.sh`](../deploy/enable-api.sh) constrói e inicia a aplicação. A API e suas rotas estão descritas em [`backend/README.md`](../backend/README.md).

## Preparar a Backend 1

O script base instala Docker/Compose, cria `/opt/dado-seguro/compose.yaml`, volume persistente para PostgreSQL e três segredos aleatórios em arquivos protegidos fora do Git: `.db_password`, `.admin_password` e `.session_secret`.

```powershell
scp -i "C:\caminho\backend.pem" .\deploy\setup-backend.sh ubuntu@IP_PRIVADO:/tmp/setup-backend.sh
ssh -i "C:\caminho\backend.pem" ubuntu@IP_PRIVADO "sudo bash /tmp/setup-backend.sh"
```

## Publicar a API

Na raiz do repositório, compile antes de copiar para manter baixo o uso de memória durante a construção da imagem na EC2:

```powershell
Push-Location .\backend
npm ci
npm run build
Pop-Location
```

Copie `backend/` e `deploy/compose.application.yaml` para `/opt/dado-seguro/backend` e `/opt/dado-seguro/deploy/compose.application.yaml`. Então, na instância:

```bash
sudo bash /opt/dado-seguro/deploy/enable-api.sh
sudo docker compose \
  -f /opt/dado-seguro/compose.yaml \
  -f /opt/dado-seguro/deploy/compose.application.yaml ps
```

O script `enable-api.sh` prepara a rede, sobe API e banco e espera a verificação de saúde. As senhas e o segredo de sessão são montados nos serviços que precisam deles, sem entrar no Git ou na imagem.

## Publicar o frontend e configurar os proxies

Gere o frontend usando o proxy same-origin:

```powershell
cd frontend
npm ci
$env:VITE_USE_MOCK = "false"
$env:VITE_API_URL = "/api"
npm run build
```

Copie o conteúdo de `frontend/dist/` para `/var/www/dadoseguro` na instância frontend. Configure Nginx com [`deploy/nginx-frontend.conf.example`](../deploy/nginx-frontend.conf.example), preenchendo `BACKEND_PRIVATE_IP` com o endereço privado atual. Na Backend 1, configure [`deploy/nginx-backend-api.conf.example`](../deploy/nginx-backend-api.conf.example), que encaminha ao processo em loopback. Valide e recarregue Nginx após substituir o placeholder:

```bash
sudo nginx -t && sudo systemctl reload nginx
```

O health check público é `GET /api/healthz`; a API também oferece `GET /healthz` internamente. A aplicação implantada é uma demonstração HTTP e não deve receber senhas reutilizadas nem documentos reais até habilitar TLS.

## Operação do banco e volumes

```bash
sudo docker compose -f /opt/dado-seguro/compose.yaml \
  -f /opt/dado-seguro/deploy/compose.application.yaml ps
sudo docker compose -f /opt/dado-seguro/compose.yaml logs --tail=100 db api
sudo docker compose -f /opt/dado-seguro/compose.yaml exec -T db \
  pg_isready -U dadoseguro_app -d dadoseguro
```

Os dados PostgreSQL e os arquivos usam volumes locais. Não use `docker compose down -v` numa instalação com dados que deseja preservar. Um volume na EC2 não é backup externo.

A senha aleatória do administrador inicial fica em `/opt/dado-seguro/.admin_password` e pode ser lida apenas diretamente na instância por administrador. Ela não é versionada. A primeira versão cria somente a conta `admin`; não há cadastro nem troca de senha pela interface.

## Limites e próximos passos

- HTTP não cifra tráfego; habilite HTTPS/TLS antes de usar credenciais ou documentos reais.
- A API marca `encrypted=false`; o conteúdo dos arquivos não é criptografado pela aplicação.
- Banco e arquivos têm somente persistência local. Automatize cópia externa e teste de restauração.
- Esta implantação publica a aplicação em uma Backend 1; não há balanceamento ou failover da API.
- O esquema inicial é criado pela API na inicialização; ainda não há migrações versionadas.
- A instância `t3.micro` tem recursos limitados; monitore memória e disco.

## Referências oficiais

- [Instalar Docker Engine no Ubuntu](https://docs.docker.com/engine/install/ubuntu/)
- [Docker Compose em produção](https://docs.docker.com/compose/how-tos/production/)
- [Secrets no Docker Compose](https://docs.docker.com/compose/how-tos/use-secrets)
