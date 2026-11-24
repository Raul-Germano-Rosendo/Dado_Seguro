# 1. Visão geral

## Objetivo

O **Dado Seguro** é um projeto acadêmico de infraestrutura/redes com uma aplicação web simples para autenticação e gestão de arquivos. Este repositório registra a arquitetura, a aplicação e os procedimentos de implantação.

O escopo atual é uma demonstração: login de administrador, listagem, upload, download e exclusão de arquivos e auditoria básica. Não há cadastro de usuários, criptografia do conteúdo dos arquivos nem política para dados reais.

## Escopo documentado

- AWS EC2 e acesso administrativo via SSH.
- Regras de firewall / Security Group.
- VPN para acesso privado via OpenVPN, com certificados gerenciados por EasyRSA.
- Nginx como proxy reverso e possível ponto de entrada web.
- Interface web em React/Vite, atualmente com modo demonstração em memória.
- API Node.js/TypeScript, sessão no PostgreSQL, autorização, upload/download e auditoria básica.
- PostgreSQL 16 em Docker/Compose com tabelas criadas automaticamente na inicialização e volume local persistente.

## Estado de implementação

| Componente | Estado |
|---|---|
| Documentação e estrutura | Preparada neste repositório |
| AWS / EC2 | Quatro instâncias `t3.micro` foram observadas em execução no snapshot de 22/11/2026; detalhes em [Estado da implantação](09-estado-implantacao.md) |
| VPN e certificados | OpenVPN e EasyRSA utilizados anteriormente; saúde atual e acesso VPN à VPC precisam ser confirmados |
| Nginx | Configuração histórica de proxy/balanceamento com dois primários e um backup; validar serviços e endereços atuais |
| Frontend | React/Vite servido pelo Nginx; chamadas same-origin para `/api` |
| Backend / API | Node.js/TypeScript em contêiner; rotas documentadas em `backend/README.md` |
| Banco de dados | PostgreSQL 16 em contêiner; tabelas de usuário, sessão, arquivos e auditoria |
| Docker / Compose | API e banco no Compose da Backend 1; instalação em `deploy/setup-backend.sh` |

## Premissas e limites

Na branch `test1.0`, a aplicação é restrita à faixa OpenVPN e acessada pelo IP privado da Frontend; o IP público retorna 403 fora do túnel. O acesso privado usa HTTP encapsulado no OpenVPN. PostgreSQL e API executam em Docker Compose, com schema SQL versionado. SFTP está limitado a uma pasta separada. O balanceamento/failover e os backups externos ainda serão preparados para as provas. Não inclua dados reais ou credenciais neste repositório.
