# 2. Arquitetura proposta

## Visão lógica

```text
Navegador --HTTPS--> Nginx Frontend (React/Vite)
                         | /api
                         v
                  Nginx Backend (proxy)
                         | loopback:3000
                         v
                  API em Docker Compose ---> PostgreSQL 16
                         |                      rede Docker privada
                         +--> volume local de arquivos
```

Frontend React/Vite, API Express e PostgreSQL 16 foram integrados. O Nginx frontend serve os arquivos estáticos e encaminha `/api` para o Nginx da Backend 1; este envia ao processo API em `127.0.0.1:3000`. A API acessa o banco via `db:5432` dentro da rede privada do Compose. O banco não publica porta no host. Arquivos são persistidos em volume local Docker. O TLS termina no frontend; o caminho interno na VPC continua HTTP. A demonstração usa uma única instância backend e não oferece alta disponibilidade ou backup externo.

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
