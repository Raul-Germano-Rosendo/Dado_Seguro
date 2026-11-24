# 9. Estado da implantação e pendências

## Evidência disponível

O snapshot abaixo foi fornecido pelo responsável pelo projeto em **22/11/2026 às 21:51 (GMT-3)**. Ele mostra instâncias EC2 no estado `Executando`; não confirma a saúde dos serviços, as regras de rede, nem a disponibilidade HTTP/VPN.

| Papel | Quantidade | Estado | Tipo | AZ | Sistema |
|---|---:|---|---|---|---|
| Frontend | 1 | Executando | `t3.micro` | `us-east-1c` | Linux/UNIX |
| Backend | 2 | Executando | `t3.micro` | `us-east-1c` | Linux/UNIX |
| Backup | 1 | Executando | `t3.micro` | `us-east-1c` | Linux/UNIX |

O snapshot mostra monitoramento detalhado desabilitado. IDs de instância, nomes de recursos, grupos de segurança, IPs e DNS foram omitidos deste inventário publicado. Consulte o console AWS autorizado para esses dados.

Em verificação remota em 23/11/2026, a Backend 1 Ubuntu 26.04 executa Docker/Compose, PostgreSQL 16 e API Node.js/TypeScript. A API está saudável, conectada ao banco e publicada somente em loopback; PostgreSQL não publica porta no host. Na Frontend, Nginx serve React e HTTPS com certificado Let's Encrypt de IP; HTTP redireciona para HTTPS, e o timer Certbot está ativo. O health check público `https://IP_PUBLICO_FRONTEND/api/healthz` respondeu 200. A regra TCP 443 já existia no Security Group Frontend. Na Backend 1, o usuário SFTP `dado-sftp` está restrito a uma pasta chroot, sem shell e sem senha; o teste de envio/recebimento foi aprovado. O conteúdo SFTP fica separado dos arquivos cadastrados pelo painel. Veja [deploy](10-deploy-docker-postgresql.md).

Em 24/11/2026, o schema `backend/db/init/001_initial_schema.sql` foi mapeado como somente leitura em `/docker-entrypoint-initdb.d` e executado sem apagar dados; as tabelas `app_users`, `stored_files`, `audit_entries` e `app_sessions` foram confirmadas. A persistência também foi verificada ao parar e reiniciar API e PostgreSQL sem remover volumes: a contagem de usuários permaneceu `1` e o health check voltou a `ok`. Na branch `test1.0`, OpenVPN envia a rota `/32` para a Frontend privada e Nginx permite somente `10.8.0.0/24`. Teste pelo túnel no próprio host respondeu `200` para a página e a API; do computador fora da VPN, HTTP, HTTPS e API no IP público responderam `403`. Este computador ainda não tinha rota VPN ativa, então o teste de cliente Windows após reconexão permanece pendente.

## Arquitetura registrada anteriormente

O contexto técnico consolidado em 22/11/2026 descreve uma VPC, uma subnet e endereços privados para cada instância. Os detalhes de rede foram omitidos deste inventário publicado; confirme CIDRs, subnets e endereços privados no console/hosts antes de usá-los, pois não vieram no snapshot atual.

O mesmo contexto informa que o frontend já foi configurado com Nginx e OpenVPN; o Nginx distribuía tráfego HTTP entre os dois backends e reservava o backup como `backup`. Foram relatados testes anteriores de distribuição e failover bem-sucedidos. OpenVPN principal foi descrito com uma rede VPN `10.8.0.0/24` e um cliente de teste. Esses são registros históricos, não validação do estado atual. Um teste anterior parou o Nginx dos backends primários, sem confirmação de que ambos foram iniciados novamente.

## O que ainda falta no repositório

- Evidências recentes e reproduzíveis do estado dos serviços e da conectividade entre as quatro instâncias.
- Confirmação do estado do Nginx nos backends primários e do upstream atual no frontend.
- Confirmação do OpenVPN principal, do túnel de teste e da ausência de conflito com a configuração antiga.
- Decisão e documentação do acesso VPN à VPC: rotas do cliente, encaminhamento IP, regras `FORWARD`, NAT ou rotas de retorno, Security Groups, NACLs e persistência após reinicialização.
- Documentação das subnets e route tables atuais, endereços privados atuais, e regras de entrada/saída dos Security Groups.
- Procedimento documentado de backup e restauração testada; a existência de uma EC2 chamada “Backup” não prova que os dados ou configurações tenham cópias restauráveis.
- Migrações versionadas para evolução do esquema (a API atualmente cria o esquema inicial ao iniciar).
- Backup externo automatizado e teste de restauração; os volumes atuais são persistência local.
- Certificados de IP têm validade de seis dias; manter o timer Certbot, o hook de reload e alertas de renovação monitorados.
- Cadastro/gestão segura de usuários e troca de senha; atualmente existe apenas o administrador inicial.
- Alta disponibilidade e balanceamento: implantação atual da aplicação encaminha para uma única Backend 1.
- Automatização segura e reproduzível da infraestrutura e da implantação, além de monitoramento, alertas, atualização e plano de rollback.

## Próxima coleta recomendada

Para conferir a aplicação, use `curl http://127.0.0.1:3000/healthz` na Backend 1 e abra a URL HTTPS publicada no navegador; `/api/healthz` deve indicar API saudável. O fluxo usa uma backend e não expõe PostgreSQL. Para verificar a arquitetura de rede/VPN mais ampla, confirme IPs privados, serviços e regras no console AWS antes de alterar forwarding ou firewall.

## Cuidado com os registros

Este documento diferencia o snapshot recebido de relatos anteriores. Atualize a tabela somente a partir de nova evidência datada. Não inclua chaves privadas, arquivos `.pem`/`.key`, perfis de cliente preenchidos, tokens ou credenciais. Consulte [Rede e VPN](04-rede-vpn.md), [Nginx](05-nginx.md) e [Segurança](06-seguranca.md) para os modelos e princípios, que não substituem a validação da infraestrutura ativa.
