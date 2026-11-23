# 5. Nginx e proxy reverso

O Nginx pode receber requisições web e encaminhá-las a um serviço interno, evitando expor diretamente o upstream. Ivan demonstra Nginx como proxy reverso e balanceador; Kitsune documenta Nginx junto com HAProxy. O modelo local usa um upstream futuro e não habilita balanceamento.

`config/nginx/dado-seguro.conf.example` é um exemplo HTTP ilustrativo, com domínio e serviço placeholders. Em produção, configure TLS com certificado válido, redirecionamento HTTP→HTTPS, cabeçalhos revisados, limites e logs. CORS deve ser definido no ponto apropriado, com origens explícitas.

O frontend React/Vite existe no repositório, mas ainda não está conectado a uma API implantada. Por isso, `127.0.0.1:3000` continua sendo apenas um placeholder. Configure o proxy da API depois que o serviço backend estiver implementado e acessível; não aponte Nginx para um serviço inexistente.
