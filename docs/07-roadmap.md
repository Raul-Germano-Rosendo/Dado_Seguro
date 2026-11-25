# 7. Próximas etapas

## 1 — Requisitos

- Descrever finalidade do Dado Seguro, usuários e fluxos principais.
- Identificar dados tratados, criticidade, retenção e requisitos acadêmicos.
- Definir região AWS, orçamento e ambiente de demonstração.

## 2 — Rede e acesso

- Desenhar VPC, sub-redes, CIDRs e rotas.
- Registrar a configuração OpenVPN efetivamente usada, endereçamento, certificados, rotas e método de administração sem publicar segredos.
- Restringir a aplicação à VPN e comprovar bloqueio pelo IP público.
- Revisar Security Groups e firewall do sistema.

## 3 — Aplicação (base implantada)

- API, login, sessão, autorização básica, upload/download e auditoria implementados conforme `frontend/src/services/api.ts`.
- API conectada ao PostgreSQL no Compose; schema inicial fica em script SQL mapeado para o container e aplicado pelo deploy.
- Permitir gestão segura de contas e senhas.
- Criar migrações versionadas e estratégia de backup externo, com teste de restauração.

## 4 — Implantação

- API e PostgreSQL implantados no Docker Compose da Backend 1; frontend e proxy publicados.
- Avaliar um domínio próprio e decidir se HAProxy ou serviço gerenciado é necessário.
- Automatizar implantação e documentar rollback.

## 5 — Operação

- Confirmar conectividade permitida e bloqueio de tráfego não autorizado; acesso público bloqueado e cliente VPN validado em 25/11/2026.
- Verificar logs, atualização, backup/restauração e custos.
- Registrar evidências da implantação real sem expor dados sensíveis.

Estas etapas registram o que falta para sair da demonstração. O estado efetivamente implantado está em [Estado da implantação](09-estado-implantacao.md).

> Atualização de 25/11/2026: frontend, API, PostgreSQL, SFTP e OpenVPN foram integrados. O schema SQL está versionado e a persistência foi conferida após reiniciar os containers. O cliente OpenVPN acessa o frontend privado, enquanto o acesso público retorna `403`. Docker e arquivos de réplica estão nos nós secundários; balanceamento/failover, storage compartilhado e backup externo com restauração continuam pendentes.
