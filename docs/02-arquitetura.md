# 2. Arquitetura proposta

## Visão lógica

```text
Usuário / navegador
        | HTTPS (após domínio e certificado)
        v
Entrada pública controlada (EC2/Nginx existente; configuração atual a confirmar)
        | VPN para administração e comunicação privada
        v
Frontend / API (a implementar) ---> Banco de dados (a projetar, acesso privado)
```

O desenho da aplicação continua conceitual, pois frontend, API e banco não estão neste repositório. A infraestrutura AWS, porém, tem quatro EC2 registradas como em execução no snapshot de 22/11/2026. Relatos anteriores descrevem Nginx no frontend distribuindo HTTP entre dois backends com uma instância de backup e OpenVPN no frontend. Consulte [Estado da implantação](09-estado-implantacao.md): esses relatos ainda precisam de validação operacional atual.

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
| Nginx | Proxy reverso/entrada web | Exemplo incluso, upstream placeholder |
| Frontend e API | Interface e regras do sistema | Futuro |
| Banco de dados | Persistência | Futuro |
| Docker | Empacotamento e execução | Futuro |

## Decisões em aberto

Definir região AWS, quantidade e papel das instâncias, sub-redes públicas/privadas, domínio e TLS, stack, banco, backups, monitoramento, disponibilidade e eventual uso de HAProxy ou balanceador gerenciado.
