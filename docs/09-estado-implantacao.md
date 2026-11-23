# 9. Estado da implantação e pendências

## Evidência disponível

O snapshot abaixo foi fornecido pelo responsável pelo projeto em **22/11/2026 às 21:51 (GMT-3)**. Ele mostra instâncias EC2 no estado `Executando`; não confirma a saúde dos serviços, as regras de rede, nem a disponibilidade HTTP/VPN.

| Papel | Quantidade | Estado | Tipo | AZ | Sistema |
|---|---:|---|---|---|---|
| Frontend | 1 | Executando | `t3.micro` | `us-east-1c` | Linux/UNIX |
| Backend | 2 | Executando | `t3.micro` | `us-east-1c` | Linux/UNIX |
| Backup | 1 | Executando | `t3.micro` | `us-east-1c` | Linux/UNIX |

O snapshot mostra monitoramento detalhado desabilitado. IDs de instância, nomes de recursos, grupos de segurança, IPs e DNS foram omitidos deste inventário publicado. Consulte o console AWS autorizado para esses dados.

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
- Implementação da aplicação (frontend/API), especificação dos requisitos e do modelo de dados, banco de dados e estratégia de implantação. O repositório contém apenas documentos e exemplos de configuração.
- Automatização segura e reproduzível da infraestrutura e da implantação, além de monitoramento, alertas, atualização e plano de rollback.

## Próxima coleta recomendada

Faça verificações somente de leitura primeiro: confirme IPs privados, serviços e regras no console AWS; no frontend, consulte `systemctl status nginx openvpn@server-tls-final`, `nginx -t`, `ip -br addr`, `ip route`, `sysctl net.ipv4.ip_forward`, `iptables -S` e `iptables -t nat -S`; teste HTTP para cada backend usando o IP privado confirmado. Para VPN, valide conexão do cliente e rota para a VPC antes de alterar forwarding ou firewall. Não pare serviços nem modifique Security Groups para produzir evidência sem avaliar impacto.

## Cuidado com os registros

Este documento diferencia o snapshot recebido de relatos anteriores. Atualize a tabela somente a partir de nova evidência datada. Não inclua chaves privadas, arquivos `.pem`/`.key`, perfis de cliente preenchidos, tokens ou credenciais. Consulte [Rede e VPN](04-rede-vpn.md), [Nginx](05-nginx.md) e [Segurança](06-seguranca.md) para os modelos e princípios, que não substituem a validação da infraestrutura ativa.
