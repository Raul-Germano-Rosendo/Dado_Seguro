# 5. Nginx e proxy reverso

O Nginx pode receber requisições web e encaminhá-las a um serviço interno, evitando expor diretamente o upstream. Ivan demonstra Nginx como proxy reverso e balanceador; Kitsune documenta Nginx junto com HAProxy. O modelo local usa um upstream futuro e não habilita balanceamento.

`config/nginx/dado-seguro.conf.example` é um exemplo HTTP ilustrativo, com domínio e serviço placeholders. Em produção, configure TLS com certificado válido, redirecionamento HTTP→HTTPS, cabeçalhos revisados, limites e logs. CORS deve ser definido no ponto apropriado, com origens explícitas.

Como frontend e API ainda não existem, `127.0.0.1:3000` é somente um placeholder. Ajuste quando a arquitetura estiver definida; não configure proxy para serviços inexistentes.
