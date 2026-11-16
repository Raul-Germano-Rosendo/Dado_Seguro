# 1. Visão geral

## Objetivo

O **Dado Seguro** é o projeto acadêmico do aluno para infraestrutura/redes. Este repositório registra a infraestrutura pretendida, conceitos estudados nos projetos de referência e modelos explicativos para orientar etapas futuras.

A finalidade funcional detalhada, os tipos de dados tratados e os perfis de usuário ainda devem ser especificados antes do desenho do banco e das políticas de segurança.

## Escopo documentado

- AWS EC2 e acesso administrativo via SSH.
- Regras de firewall / Security Group.
- VPN para acesso privado via OpenVPN, com certificados gerenciados por EasyRSA.
- Nginx como proxy reverso e possível ponto de entrada web.
- CORS a definir quando frontend e API existirem.
- Frontend, backend, banco e containerização como fases posteriores.

## Estado de implementação

| Componente | Estado |
|---|---|
| Documentação e estrutura | Preparada neste repositório |
| AWS / EC2 | A configurar; modelo não representa recurso existente |
| VPN e certificados | OpenVPN e EasyRSA utilizados; modelos genéricos, materiais criptográficos reais não incluídos |
| Nginx | Modelo genérico; upstream ainda não existe |
| Frontend | Futuro |
| Backend / API | Não especificado neste material |
| Banco de dados | Futuro; tecnologia e esquema pendentes |
| Docker / Compose | Futuro |

## Premissas e limites

Os exemplos não foram aplicados nem testados em conta AWS. Região, sistema operacional, CIDRs, endereços, domínio, portas e disponibilidade precisam ser decididos. Não inclua dados reais ou credenciais neste repositório.
