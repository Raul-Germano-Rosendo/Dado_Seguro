# Roteiro de provas do professor

Este roteiro organiza as verificações práticas da branch `test1.0`. Faça as provas na ordem abaixo e use somente arquivos fictícios.

## Situação atual

| Prova | Situação | Evidência verificada |
|---|---|---|
| Aplicação somente via VPN | Configurada | Fora da VPN, HTTP, HTTPS e API no IP público respondem `403`; pelo túnel no host Frontend, página e API respondem `200`. Falta reconectar o cliente Windows e confirmar o navegador do aluno. |
| Persistência PostgreSQL | Configurada e exercitada | API e banco foram parados e iniciados sem remover volumes; a contagem de usuários permaneceu igual e a API voltou saudável. |
| Dockerfile e Compose na AWS | Publicados | Dockerfile e os arquivos Compose estão em `/opt/dado-seguro` na Backend 1. |
| Tabelas via script SQL montado | Configurado e exercitado | `001_initial_schema.sql` é montado como somente leitura no container PostgreSQL; as quatro tabelas foram listadas. |
| Nginx com dois backends e servidor backup | **Pendente** | O Nginx atual encaminha para uma única Backend 1. Não pare a API esperando failover até concluir essa etapa. |

## Sequência recomendada

1. Conecte o OpenVPN no computador do aluno e confirme a rota para `172.31.30.175`.
2. Mostre ao professor que `https://23.22.200.189` retorna `403` sem VPN.
3. Com VPN conectada, abra `http://172.31.30.175` e confirme `/api/healthz`.
4. Entre com a conta autorizada, envie um arquivo fictício e verifique a linha em PostgreSQL.
5. Mostre o Dockerfile, o Compose e o volume persistente.
6. Pare e inicie os containers **sem remover os volumes**; confirme que o arquivo continua na lista e pode ser baixado.
7. Demonstre Nginx/load balancing/failover somente quando Backend 2 e Backup estiverem configurados e a seção [Nginx e failover](05-nginx-load-balancer-backup.md) deixar de estar pendente.

## Acesso e cautelas

- Site pela VPN: `http://172.31.30.175`
- IP público, que deve ser bloqueado fora da VPN: `https://23.22.200.189`
- Faixa dos clientes VPN: `10.8.0.0/24`
- Endpoint OpenVPN atual: `23.22.200.189:1194/UDP`
- O acesso ao IP privado usa HTTP encapsulado no túnel OpenVPN. O Compose de `test1.0` deixa o cookie sem a flag `Secure` para permitir a sessão nesse HTTP interno; não exponha a aplicação fora da política VPN.
- Nunca execute `docker compose down -v` durante a prova: `-v` remove os volumes que mantêm banco e arquivos.
- Não mostre nem copie os arquivos `.pem`, segredos Compose, senha do administrador ou perfil OpenVPN.

## Páginas por prova

- [01 — Acesso via VPN](01-vpn-acesso.md)
- [02 — Persistência dos dados](02-persistencia.md)
- [03 — Dockerfile e Compose](03-docker-compose.md)
- [04 — Tabelas PostgreSQL](04-postgresql-schema.md)
- [05 — Nginx, balanceamento e servidor backup](05-nginx-load-balancer-backup.md)
