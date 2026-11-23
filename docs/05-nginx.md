# 5. Nginx e proxy reverso

O Nginx pode receber requisições web e encaminhá-las a um serviço interno, evitando expor diretamente o upstream. Ivan demonstra Nginx como proxy reverso e balanceador; Kitsune documenta Nginx junto com HAProxy. O modelo local usa um upstream futuro e não habilita balanceamento.

`config/nginx/dado-seguro.conf.example` é um exemplo HTTP ilustrativo, com domínio e serviço placeholders. Em produção, configure TLS com certificado válido, redirecionamento HTTP→HTTPS, cabeçalhos revisados, limites e logs. CORS deve ser definido no ponto apropriado, com origens explícitas.

Na demonstração implantada, a instância frontend serve o build estático em `/var/www/dadoseguro` e encaminha `/api/` para a Backend 1. O Nginx backend encaminha para a API em `127.0.0.1:3000`. Os exemplos estão em `deploy/nginx-frontend.conf.example` e `deploy/nginx-backend-api.conf.example`; use o endereço privado atual do backend. O script `deploy/configure-https.sh` instala Certbot, obtém o certificado para o IP frontend, ativa HTTPS e redireciona HTTP.

O endpoint `GET /api/healthz` verifica a API e sua conexão com o banco. O Nginx da Backend 1 preserva `X-Forwarded-Proto` enviado pelo frontend para que a sessão `Secure` reconheça o acesso HTTPS, embora a conexão interna da VPC use HTTP.
