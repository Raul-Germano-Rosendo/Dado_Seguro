# 6. Segurança e CORS

## Princípios

- Menor privilégio em IAM, Security Groups, rotas e usuários.
- Separar interfaces públicas e privadas; manter banco e administração sem exposição direta.
- Guardar segredos fora do Git e não colocá-los em scripts, imagens ou logs.
- Aplicar atualizações e registrar mudanças.
- Usar TLS para tráfego web público quando a aplicação for publicada.

## CORS

CORS é uma política do navegador que controla quais origens podem ler respostas de uma API. Não é autenticação nem firewall. Quando frontend e API existirem, listar somente origens autorizadas (esquema, host e porta), métodos e cabeçalhos necessários. Evitar `*` com credenciais. Tratar preflight `OPTIONS` e não refletir origens arbitrárias recebidas no cabeçalho `Origin`.

Como URLs de frontend e API ainda não existem, não há política CORS executável neste repositório.

## Dados e privacidade

Antes de escolher banco ou tabelas, documentar dados coletados, finalidade, retenção, acesso e proteção. Usar dados fictícios em desenvolvimento e não registrar informações pessoais ou segredos em issues, commits ou capturas de tela.
