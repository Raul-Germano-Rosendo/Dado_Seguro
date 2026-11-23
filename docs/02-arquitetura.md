# 2. Arquitetura proposta

## Visão lógica

```text
Navegador
   | interface React/Vite (modo demo hoje)
   v
Nginx / entrada web (configuração e publicação a confirmar)
   | API a implementar
   v
Backend em Docker Compose ---> PostgreSQL 16 em rede Docker privada
```

O frontend React/Vite foi integrado à `main` e oferece uma demonstração com dados em memória. Seu contrato de API está em `frontend/src/services/api.ts`. Em 23/11/2026, Docker e PostgreSQL 16 foram iniciados na Backend 1; o PostgreSQL não publica porta no host. A API ainda precisa ser implementada e adicionada ao mesmo Compose para conectar ao banco pelo endereço `db:5432`. A topologia AWS mais ampla e o Nginx continuam descritos em [Estado da implantação](09-estado-implantacao.md), distinguindo relatos históricos de observações atuais.

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
| Nginx | Proxy reverso/entrada web | Modelo de proxy incluso; rota da API ainda a configurar |
| Frontend | Interface web | React/Vite no repositório; demonstração usa mock |
| API | Regras e acesso a dados | A implementar conforme contrato do frontend |
| Banco de dados | Persistência | PostgreSQL 16 em contêiner; sem esquema aplicado |
| Docker | Empacotamento e execução | Engine/Compose instalados na Backend 1; serviço descrito no guia de deploy |

## Decisões em aberto

Definir região AWS, quantidade e papel das instâncias, sub-redes públicas/privadas, domínio e TLS, stack, banco, backups, monitoramento, disponibilidade e eventual uso de HAProxy ou balanceador gerenciado.
