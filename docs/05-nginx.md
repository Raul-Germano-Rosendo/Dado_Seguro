# 5. Nginx e proxy reverso

O Nginx pode receber requisições web e encaminhá-las a um serviço interno, evitando expor diretamente o upstream. Ivan demonstra Nginx como proxy reverso e balanceador; Kitsune documenta Nginx junto com HAProxy. O modelo local usa um upstream futuro e não habilita balanceamento.

`config/nginx/dado-seguro.conf.example` é um exemplo HTTP ilustrativo, com domínio e serviço placeholders. Em produção, configure TLS com certificado válido, redirecionamento HTTP→HTTPS, cabeçalhos revisados, limites e logs. CORS deve ser definido no ponto apropriado, com origens explícitas.

Na demonstração implantada, a instância frontend serve o build estático em `/var/www/dadoseguro` e encaminha `/api/` para o DNS interno `api.dadoseguro.internal`. O Nginx da Backend 1 responde nesse host virtual e encaminha para a API em `127.0.0.1:3000`. Os exemplos específicos estão em `deploy/nginx-frontend.conf.example` e `deploy/nginx-backend-api.conf.example`; substitua os placeholders com os endereços privados atuais ao reproduzir a instalação. O caminho ativo da aplicação aponta para uma única backend; a configuração antiga foi preservada na instância frontend como backup local, não no Git.

O endpoint `GET /api/healthz` verifica a API e sua conexão com o banco. A publicação atual usa HTTP na porta 80. Configure TLS e redirecionamento HTTP→HTTPS antes de usar credenciais ou arquivos reais.
