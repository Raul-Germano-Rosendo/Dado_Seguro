# 5. Nginx e proxy reverso

O Nginx pode receber requisições web e encaminhá-las a um serviço interno, evitando expor diretamente o upstream. Ivan demonstra Nginx como proxy reverso e balanceador; Kitsune documenta Nginx junto com HAProxy. O modelo local usa um upstream futuro e não habilita balanceamento.

`config/nginx/dado-seguro.conf.example` é um exemplo HTTP ilustrativo, com domínio e serviço placeholders. Em produção, configure TLS com certificado válido, redirecionamento HTTP→HTTPS, cabeçalhos revisados, limites e logs. CORS deve ser definido no ponto apropriado, com origens explícitas.

Na branch `test1.0`, a instância frontend serve o build estático em `/var/www/dadoseguro` somente a clientes OpenVPN (`10.8.0.0/24`). O site é acessado pelo IP privado da Frontend, em HTTP dentro do túnel; requisições externas ao IP público recebem `403`, exceto o caminho de validação ACME. O Nginx encaminha `/api/` para a Backend 1; o Nginx backend encaminha para a API em `127.0.0.1:3000`. O script `deploy/enable-vpn-only.sh` instala a rota privada e aplica essa restrição. `deploy/configure-https.sh` mantém o certificado e a renovação ACME.

O endpoint `GET /api/healthz` verifica a API e sua conexão com o banco. Como o navegador acessa HTTP apenas dentro do túnel VPN nesta etapa, o Compose usa cookie `HttpOnly` e `SameSite=Lax` sem a flag `Secure`; não publique o Nginx fora da política VPN.
