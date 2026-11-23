# 7. Próximas etapas

## 1 — Requisitos

- Descrever finalidade do Dado Seguro, usuários e fluxos principais.
- Identificar dados tratados, criticidade, retenção e requisitos acadêmicos.
- Definir região AWS, orçamento e ambiente de demonstração.

## 2 — Rede e acesso

- Desenhar VPC, sub-redes, CIDRs e rotas.
- Registrar a configuração OpenVPN efetivamente usada, endereçamento, certificados, rotas e método de administração sem publicar segredos.
- Revisar Security Groups e firewall do sistema.

## 3 — Aplicação

- Concluir os requisitos funcionais e implementar a API conforme o contrato em `frontend/src/services/api.ts`.
- Conectar a API ao PostgreSQL no Compose e criar esquema/migrações.
- Implementar autenticação, autorização, upload/download e auditoria; configurar CORS/HTTPS para a origem publicada.
- Definir backup externo e credenciais de aplicação; nunca compartilhar a senha inicial do banco.

## 4 — Implantação

- Completar a implantação da API no Docker Compose já preparado na Backend 1.
- Configurar Nginx, domínio e TLS; decidir se HAProxy ou serviço gerenciado é necessário.
- Automatizar implantação e documentar rollback.

## 5 — Operação

- Confirmar conectividade permitida e bloqueio de tráfego não autorizado.
- Verificar logs, atualização, backup/restauração e custos.
- Registrar evidências da implantação real sem expor dados sensíveis.

Estas etapas são planejamento para a API e para a operação completa. O estado efetivamente implantado está em [Estado da implantação](09-estado-implantacao.md).

> Atualização: o frontend está no repositório e Docker/PostgreSQL foram implantados em uma instância backend em 23/11/2026. A API, esquema, migrações, backup externo e integração com Nginx continuam pendentes.
