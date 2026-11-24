# 2. Arquitetura proposta

## Visão lógica

```text
Cliente OpenVPN (10.8.0.0/24) --túnel--> Nginx Frontend (IP privado)
                                             | /api
                                             v
                                      Nginx Backend (proxy)
                                             | loopback:3000
                                             v
                                      API em Docker Compose ---> PostgreSQL 16
                                             |                      rede Docker privada
                                             +--> volume local de arquivos

Cliente fora da VPN --IP público--> Nginx Frontend (403)
```

Na branch `test1.0`, o OpenVPN entrega uma rota `/32` para o IP privado da Frontend. O Nginx libera a aplicação somente para clientes `10.8.0.0/24`; acesso pelo IP público, fora do túnel, recebe `403`. O navegador usa HTTP dentro do túnel criptografado. O Nginx frontend encaminha `/api` ao Nginx da Backend 1, que envia ao processo API em `127.0.0.1:3000`. A API acessa `db:5432` na rede privada do Compose. PostgreSQL não publica porta no host e mantém dados em volume local Docker. A configuração atual ainda usa uma Backend 1 e não oferece alta disponibilidade ou backup externo.

## Fluxos esperados

1. Acesso público à aplicação apenas pelas portas web necessárias, idealmente HTTPS.
2. Administração por SSH restrito ao IP autorizado ou por acesso privado via VPN.
3. Serviços internos sem exposição direta à internet.
4. Quando houver aplicação e banco, permitir apenas os fluxos necessários entre camadas.

## Componentes

| Camada | Função planejada | Situação |
|---|---|---|
| AWS VPC/EC2 | Hospedar componentes selecionados | Quatro EC2 em execução no snapshot; topologia atual a confirmar |
| Security Group | Filtrar tráfego | Modelo incluso |
| VPN | Acesso administrativo privado | Modelos OpenVPN inclusos |
| Nginx | Servir frontend e encaminhar `/api` | Configuração implantada e exemplos versionados |
| Frontend | Interface web | React/Vite compilado com API real |
| API | Regras e acesso a dados | Express/TypeScript em contêiner |
| Banco de dados | Persistência | PostgreSQL 16; esquema básico inicializado pela API |
| Docker | Empacotamento e execução | Compose executa API e banco na Backend 1 |

## Decisões em aberto

Definir região AWS, quantidade e papel das instâncias, sub-redes públicas/privadas, domínio e TLS, stack, banco, backups, monitoramento, disponibilidade e eventual uso de HAProxy ou balanceador gerenciado.
