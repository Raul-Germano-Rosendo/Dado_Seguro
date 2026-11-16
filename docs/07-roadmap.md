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

- Escolher stack e implementar frontend e API.
- Definir autenticação, autorização e política CORS para origens reais.
- Projetar banco, migrações, backups e credenciais.

## 4 — Implantação

- Avaliar Docker/Compose e separar configurações de desenvolvimento e implantação.
- Configurar Nginx, domínio e TLS; decidir se HAProxy ou serviço gerenciado é necessário.
- Automatizar implantação e documentar rollback.

## 5 — Operação

- Confirmar conectividade permitida e bloqueio de tráfego não autorizado.
- Verificar logs, atualização, backup/restauração e custos.
- Registrar evidências da implantação real sem expor dados sensíveis.

Estas etapas são planejamento. A documentação atual não afirma que os componentes estejam implantados.
