# 2. Arquitetura proposta

## Visão lógica

```text
Usuário / navegador
        | HTTPS (após domínio e certificado)
        v
Entrada pública controlada (futura EC2/Nginx ou serviço equivalente)
        | VPN para administração e comunicação privada
        v
Frontend / API (a implementar) ---> Banco de dados (a projetar, acesso privado)
```

Este desenho é conceitual, não representa recursos implantados. O Kitsune demonstra duas EC2 conectadas por WireGuard, HAProxy, Nginx e serviços em Docker/PostgreSQL. O guia de Ivan aborda EC2, OpenVPN, Nginx, CORS e exemplos. No Dado Seguro, a VPN utilizada foi OpenVPN; os modelos locais representam essa escolha.

## Fluxos esperados

1. Acesso público à aplicação apenas pelas portas web necessárias, idealmente HTTPS.
2. Administração por SSH restrito ao IP autorizado ou por acesso privado via VPN.
3. Serviços internos sem exposição direta à internet.
4. Quando houver aplicação e banco, permitir apenas os fluxos necessários entre camadas.

## Componentes

| Camada | Função planejada | Situação |
|---|---|---|
| AWS VPC/EC2 | Hospedar componentes selecionados | A definir |
| Security Group | Filtrar tráfego | Modelo incluso |
| VPN | Acesso administrativo privado | Modelos OpenVPN inclusos |
| Nginx | Proxy reverso/entrada web | Exemplo incluso, upstream placeholder |
| Frontend e API | Interface e regras do sistema | Futuro |
| Banco de dados | Persistência | Futuro |
| Docker | Empacotamento e execução | Futuro |

## Decisões em aberto

Definir região AWS, quantidade e papel das instâncias, sub-redes públicas/privadas, domínio e TLS, stack, banco, backups, monitoramento, disponibilidade e eventual uso de HAProxy ou balanceador gerenciado.
