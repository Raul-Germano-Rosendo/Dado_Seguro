# 6. Segurança e CORS

## Princípios

- Menor privilégio em IAM, Security Groups, rotas e usuários.
- Separar interfaces públicas e privadas; manter banco e administração sem exposição direta.
- Guardar segredos fora do Git e não colocá-los em scripts, imagens ou logs.
- Aplicar atualizações e registrar mudanças.
- Usar TLS para tráfego web público quando a aplicação for publicada.

## CORS

CORS é uma política do navegador que controla quais origens podem ler respostas de uma API. Não é autenticação nem firewall. Na implantação atual, o frontend chama a API no mesmo host por `/api`, sem CORS entre origens. Se a API for publicada em host distinto, liste explicitamente origens, métodos e cabeçalhos necessários. Evite `*` com credenciais e não reflita origens arbitrárias recebidas no cabeçalho `Origin`.

Na configuração de prova da branch `test1.0`, Nginx libera a aplicação apenas para `10.8.0.0/24`, e o cliente usa o IP privado da Frontend dentro do túnel OpenVPN. O IP público responde `403` para acessos externos; o caminho ACME continua público para renovar o certificado Let's Encrypt de IP. O navegador usa HTTP dentro do túnel, então a sessão usa cookie `HttpOnly` e `SameSite=Lax` sem `Secure`; não use esse modo sem VPN. A API não criptografa os conteúdos armazenados; arquivos ficam em volume local. Use somente dados fictícios até implantar cópias externas e gestão de usuários adequada.

O usuário SFTP `dado-sftp` não recebe shell nem autenticação por senha: usa chave SSH e fica preso a `/srv/sftp/dado-sftp/upload`. Essa pasta é uma área de recebimento separada; arquivos enviados por SFTP não aparecem automaticamente no painel.

## Dados e privacidade

O banco contém usuário, sessões, metadados dos arquivos e eventos básicos de auditoria. O conteúdo está em armazenamento local. O administrador inicial é criado da senha aleatória mantida fora do Git em `/opt/dado-seguro/.admin_password`. Não há cadastro de usuários ou troca de senha na interface atual. Usar dados fictícios em desenvolvimento e não registrar informações pessoais ou segredos em issues, commits ou capturas de tela.
