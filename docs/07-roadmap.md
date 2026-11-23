# 7. Próximas etapas

## 1 — Requisitos

- Descrever finalidade do Dado Seguro, usuários e fluxos principais.
- Identificar dados tratados, criticidade, retenção e requisitos acadêmicos.
- Definir região AWS, orçamento e ambiente de demonstração.

## 2 — Rede e acesso

- Desenhar VPC, sub-redes, CIDRs e rotas.
- Registrar a configuração OpenVPN efetivamente usada, endereçamento, certificados, rotas e método de administração sem publicar segredos.
- Revisar Security Groups e firewall do sistema.

## 3 — Aplicação (base implantada)

- API, login, sessão, autorização básica, upload/download e auditoria implementados conforme `frontend/src/services/api.ts`.
- API conectada ao PostgreSQL no Compose; tabelas iniciais são garantidas na inicialização.
- Configurar TLS para a origem publicada e permitir gestão segura de contas/senhas.
- Criar migrações versionadas e estratégia de backup externo, com teste de restauração.

## 4 — Implantação

- API e PostgreSQL implantados no Docker Compose da Backend 1; frontend e proxy publicados.
- Configurar domínio e TLS; decidir se HAProxy ou serviço gerenciado é necessário.
- Automatizar implantação e documentar rollback.

## 5 — Operação

- Confirmar conectividade permitida e bloqueio de tráfego não autorizado.
- Verificar logs, atualização, backup/restauração e custos.
- Registrar evidências da implantação real sem expor dados sensíveis.

Estas etapas registram o que falta para sair da demonstração. O estado efetivamente implantado está em [Estado da implantação](09-estado-implantacao.md).

> Atualização: frontend, API, PostgreSQL e Nginx foram integrados para demonstração em 23/11/2026. TLS, migrações, backup externo e restauração testada continuam pendentes.
