# 1. Visão geral

## Objetivo

O **Dado Seguro** é o projeto acadêmico do aluno para infraestrutura/redes. Este repositório registra a infraestrutura pretendida, conceitos estudados nos projetos de referência e modelos explicativos para orientar etapas futuras.

A finalidade funcional detalhada, os tipos de dados tratados e os perfis de usuário ainda devem ser especificados antes do desenho do banco e das políticas de segurança.

## Escopo documentado

- AWS EC2 e acesso administrativo via SSH.
- Regras de firewall / Security Group.
- VPN para acesso privado via OpenVPN, com certificados gerenciados por EasyRSA.
- Nginx como proxy reverso e possível ponto de entrada web.
- Interface web em React/Vite, atualmente com modo demonstração em memória.
- API e CORS a implementar conforme o contrato usado pelo frontend.
- PostgreSQL 16 em Docker/Compose em uma instância backend; esquema e integração com API pendentes.

## Estado de implementação

| Componente | Estado |
|---|---|
| Documentação e estrutura | Preparada neste repositório |
| AWS / EC2 | Quatro instâncias `t3.micro` foram observadas em execução no snapshot de 22/11/2026; detalhes em [Estado da implantação](09-estado-implantacao.md) |
| VPN e certificados | OpenVPN e EasyRSA utilizados anteriormente; saúde atual e acesso VPN à VPC precisam ser confirmados |
| Nginx | Configuração histórica de proxy/balanceamento com dois primários e um backup; validar serviços e endereços atuais |
| Frontend | React/Vite integrado; modo demonstração usa dados fictícios em memória |
| Backend / API | Ainda não implementado; contrato esperado está em `frontend/src/services/api.ts` |
| Banco de dados | PostgreSQL 16 em contêiner ativo; esquema, migrações e cópia externa pendentes |
| Docker / Compose | Instalado na Backend 1; implantação reproduzível em `deploy/setup-backend.sh` |

## Premissas e limites

Os exemplos de configuração continuam sendo modelos, salvo o deploy descrito em [Deploy com Docker e PostgreSQL](10-deploy-docker-postgresql.md). Endereços e saúde dos serviços devem ser confirmados no ambiente antes de operar. Não inclua dados reais ou credenciais neste repositório.
