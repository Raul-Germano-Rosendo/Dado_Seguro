# 10. Deploy com Docker, API e PostgreSQL

## Arquitetura implantada

A stack da demonstração usa uma instância backend Ubuntu com Docker Compose para API Node.js/TypeScript e PostgreSQL 16. O Nginx backend encaminha requisições para a API em `127.0.0.1:3000`; a porta PostgreSQL 5432 não é publicada no host. Na instância frontend, Nginx serve o build React/Vite e encaminha `/api/` para a backend. A interface e os dados são persistidos separadamente: metadados no PostgreSQL e conteúdo dos arquivos em volume Docker local.

O Compose base agora está versionado em [`compose.yaml`](../compose.yaml); [`deploy/setup-backend.sh`](../deploy/setup-backend.sh) instala Docker/Compose e prepara PostgreSQL. [`deploy/compose.application.yaml`](../deploy/compose.application.yaml) mapeia o script SQL para dentro do container PostgreSQL e define a API; [`deploy/enable-api.sh`](../deploy/enable-api.sh) aplica o schema e inicia a aplicação. A definição das tabelas está em [`backend/db/init/001_initial_schema.sql`](../backend/db/init/001_initial_schema.sql), e as rotas estão descritas em [`backend/README.md`](../backend/README.md).

## Preparar a Backend 1

O script base instala Docker/Compose, cria `/opt/dado-seguro/compose.yaml`, volume persistente para PostgreSQL e três segredos aleatórios em arquivos protegidos fora do Git: `.db_password`, `.admin_password` e `.session_secret`.

```powershell
scp -i "C:\caminho\backend.pem" .\deploy\setup-backend.sh ubuntu@IP_PRIVADO:/tmp/setup-backend.sh
ssh -i "C:\caminho\backend.pem" ubuntu@IP_PRIVADO "sudo bash /tmp/setup-backend.sh"
```

## Publicar a API

Copie `backend/` e `deploy/compose.application.yaml` para `/opt/dado-seguro/backend` e `/opt/dado-seguro/deploy/compose.application.yaml`. O Dockerfile multistage compila TypeScript durante o build da imagem, então não precisa instalar Node.js no host.

```bash
sudo bash /opt/dado-seguro/deploy/enable-api.sh
sudo docker compose \
  -f /opt/dado-seguro/compose.yaml \
  -f /opt/dado-seguro/deploy/compose.application.yaml ps
```

O script `enable-api.sh` monta a pasta `backend/db/init` dentro do PostgreSQL como somente leitura, executa `001_initial_schema.sql` e então sobe a API. O SQL usa `IF NOT EXISTS`, portanto pode ser repetido sem apagar os dados já gravados. A primeira inicialização do PostgreSQL também lê scripts em `/docker-entrypoint-initdb.d`; como a demonstração pode já ter um volume criado, o deploy executa o SQL explicitamente em cada atualização. As senhas e o segredo de sessão são montados nos serviços que precisam deles, sem entrar no Git ou na imagem.

Para mostrar as tabelas e os registros persistidos no banco:

```bash
sudo docker compose -f /opt/dado-seguro/compose.yaml \
  -f /opt/dado-seguro/deploy/compose.application.yaml \
  exec -T db psql -U dadoseguro_app -d dadoseguro -c '\dt'
sudo docker compose -f /opt/dado-seguro/compose.yaml \
  -f /opt/dado-seguro/deploy/compose.application.yaml \
  exec -T db psql -U dadoseguro_app -d dadoseguro \
  -c 'SELECT username, role, created_at FROM app_users ORDER BY created_at;'
```

## Publicar o frontend e configurar os proxies

Gere o frontend usando o proxy same-origin:

```powershell
cd frontend
npm ci
$env:VITE_USE_MOCK = "false"
$env:VITE_API_URL = "/api"
$env:VITE_SFTP_HOST = "IP_PUBLICO_BACKEND"
npm run build
```

Copie o conteúdo de `frontend/dist/` para `/var/www/dadoseguro` na instância frontend. Garanta que o Nginx consiga atravessar os diretórios e ler os arquivos estáticos; sem essas permissões, o fallback SPA pode responder `index.html` no lugar do JavaScript/CSS e a página fica branca:

```bash
sudo find /var/www/dadoseguro -type d -exec chmod 755 {} +
sudo find /var/www/dadoseguro -type f -exec chmod 644 {} +
```

Configure Nginx com [`deploy/nginx-frontend.conf.example`](../deploy/nginx-frontend.conf.example), preenchendo `BACKEND_PRIVATE_IP` com o endereço privado atual. Na Backend 1, configure [`deploy/nginx-backend-api.conf.example`](../deploy/nginx-backend-api.conf.example), que encaminha ao processo em loopback. Valide e recarregue Nginx após substituir o placeholder:

```bash
sudo nginx -t && sudo systemctl reload nginx
```

O health check público é `GET /api/healthz`; a API também oferece `GET /healthz` internamente.

## SFTP restrito e HTTPS

O usuário SFTP existe somente na Backend 1, não tem shell e aceita exclusivamente uma chave pública. Gere a chave pública a partir da chave privada de acesso à Backend 1 (a chave privada nunca é copiada para o servidor nem versionada):

```powershell
ssh-keygen -y -f "$env:USERPROFILE\Downloads\ChaveEC2conf2Backend.pem" | Set-Content -Encoding ascii .\dado-sftp.pub
scp -i "$env:USERPROFILE\Downloads\ChaveEC2conf2Backend.pem" .\deploy\configure-sftp.sh .\dado-sftp.pub ubuntu@IP_PUBLICO_BACKEND:/tmp/
ssh -i "$env:USERPROFILE\Downloads\ChaveEC2conf2Backend.pem" ubuntu@IP_PUBLICO_BACKEND "sudo bash /tmp/configure-sftp.sh /tmp/dado-sftp.pub; sudo rm -f /tmp/configure-sftp.sh /tmp/dado-sftp.pub"
Remove-Item .\dado-sftp.pub
```

Conecte no IP público da Backend 1, porta `22`, usuário `dado-sftp`, usando `ChaveEC2conf2Backend.pem` como chave privada. Essa chave também dá acesso administrativo ao usuário `ubuntu`; não a compartilhe com terceiros. A pasta inicial `/upload` é uma área isolada em `/srv/sftp/dado-sftp/upload`; os arquivos não aparecem automaticamente no painel da aplicação.

Na instância frontend, execute `sudo bash /tmp/configure-https.sh IP_PRIVADO_BACKEND IP_PUBLICO_FRONTEND VPN_CIDR`. O script instala Certbot e mantém o certificado de IP; HTTP e HTTPS são liberados apenas a clientes VPN, enquanto o caminho ACME continua público. Certificados de IP são válidos por seis dias; mantenha o timer Certbot e o hook de recarga ativos.

Para restringir o acesso ao OpenVPN ativo e disponibilizar a rota privada da Frontend, copie `deploy/enable-vpn-only.sh` para a instância e execute:

```bash
sudo bash /tmp/enable-vpn-only.sh IP_PRIVADO_FRONTEND IP_PRIVADO_BACKEND IP_PUBLICO_FRONTEND 10.8.0.0/24
```

O script faz backup das configurações, adiciona ao OpenVPN uma rota `/32` para a própria Frontend, limita Nginx aos clientes `10.8.0.0/24` e reinicia o serviço VPN. Os clientes precisam reconectar para receber a rota. Abra `http://IP_PRIVADO_FRONTEND` somente depois de conectar a VPN. O HTTP está dentro do túnel criptografado; por isso o Compose de `test1.0` deixa o cookie sem a flag `Secure`. Fora da VPN, acessar o IP público da Frontend deve retornar `403`.

Depois de ativar o acesso via VPN, atualize a API com a sobreposição Compose para usar a sessão no HTTP interno do túnel:

```bash
sudo docker compose -f /opt/dado-seguro/compose.yaml \
  -f /opt/dado-seguro/deploy/compose.application.yaml up -d --force-recreate api
```

No build do frontend, defina `VITE_SFTP_HOST` para o IP público atual da Backend 1. O SFTP é um canal de transferência separado do upload HTTP da aplicação.

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

- A aplicação em `test1.0` é acessível pela faixa VPN; o navegador usa HTTP somente dentro do túnel OpenVPN.
- A API marca `encrypted=false`; o conteúdo dos arquivos não é criptografado pela aplicação.
- Banco e arquivos têm somente persistência local. Automatize cópia externa e teste de restauração.
- O Nginx de balanceamento preparado em `deploy/enable-nginx-lb.sh` exige três health checks ativos. As replicas são preparadas com `deploy/compose.replica.yaml` e `deploy/setup-api-replica.sh`; veja os pré-requisitos de rede e os testes em [`docs/provas-professor/05-nginx-load-balancer-backup.md`](provas-professor/05-nginx-load-balancer-backup.md).
- O schema inicial é versionado em `backend/db/init/001_initial_schema.sql`; alterações futuras devem receber novos arquivos SQL versionados.
- A instância `t3.micro` tem recursos limitados; monitore memória e disco durante o build da imagem.

## Referências oficiais

- [Instalar Docker Engine no Ubuntu](https://docs.docker.com/engine/install/ubuntu/)
- [Docker Compose em produção](https://docs.docker.com/compose/how-tos/production/)
- [Secrets no Docker Compose](https://docs.docker.com/compose/how-tos/use-secrets)
