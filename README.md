# Dado Seguro

Documentação de infraestrutura e planejamento técnico do projeto acadêmico **Dado Seguro**.

> **Estado atual (`test1.0`):** a aplicação é acessível pela rede OpenVPN em endereço privado; o IP público retorna 403 fora da VPN. O frontend React/Vite, API Node.js/TypeScript e PostgreSQL 16 usam Docker Compose. O schema está versionado em SQL e mapeado ao container do banco. A instância ainda usa uma única API e armazenamento local; balanceamento e failover são a próxima etapa. Não envie documentos reais. Consulte [Estado da implantação](docs/09-estado-implantacao.md), [deploy](docs/10-deploy-docker-postgresql.md) e [segurança](docs/06-seguranca.md).

## Conteúdo

- [Visão geral e escopo](docs/01-visao-geral.md)
- [Arquitetura proposta](docs/02-arquitetura.md)
- [AWS e EC2](docs/03-aws-ec2.md)
- [Rede, firewall e VPN](docs/04-rede-vpn.md)
- [Certificados com EasyRSA](docs/04a-certificados-easyrsa.md)
- [Nginx e proxy reverso](docs/05-nginx.md)
- [Segurança e CORS](docs/06-seguranca.md)
- [Plano de implementação](docs/07-roadmap.md)
- [Referências e decisões](docs/08-referencias.md)
- [Estado da implantação e pendências](docs/09-estado-implantacao.md)
- [Deploy com Docker, API e PostgreSQL](docs/10-deploy-docker-postgresql.md)
- [Configurações de exemplo](config/README.md)

## Árvore do repositório

```text
Redes_Jean/
├── README.md
├── .gitignore
├── frontend/ (interface React/Vite)
├── backend/ (API Node.js/TypeScript)
├── deploy/ (instalação e publicação via Docker Compose)
├── docs/ (guias segmentados por assunto)
└── config/
    ├── aws/ (EC2 e regras de rede)
    ├── nginx/ (proxy reverso)
    └── vpn/ (modelos OpenVPN)
```

Leia primeiro `docs/` e `config/README.md`. O frontend inicia em modo mock; as configurações `.example` são modelos para adaptação. Nunca versione chaves privadas, senhas, tokens ou dados pessoais.

## Executar a demonstração web

```bash
cd frontend
npm ci
cp .env.example .env
npm run dev
```

Para modo local sem backend, use `VITE_USE_MOCK=true` no `frontend/.env`. Para apontar a interface a uma API, configure `VITE_USE_MOCK=false` e `VITE_API_URL=/api`, então gere a versão de produção com `npm run build`. O contrato está em `frontend/src/services/api.ts`. A demonstração implantada salva metadados no PostgreSQL e arquivos em volume local Docker.

## Executar a stack implantada

Veja [Deploy com Docker, API e PostgreSQL](docs/10-deploy-docker-postgresql.md) para preparar a instância, compilar e publicar a API, ativar o Nginx e operar o banco. A senha inicial de demonstração é gerada fora do repositório em `/opt/dado-seguro/.admin_password` e deve ser obtida diretamente na instância. Não há cadastro de usuários na primeira versão.

## Referências usadas

- [Kitsune Infrastructure](https://github.com/raphaelamonteiro/kitsune-infrastructure)
- [AWS Network Infrastructure for Deployment of WebApps](https://github.com/Ivan-Duarte/AWS-Network-Infrastructure-for-Deployment-of-WebApps)

Este é material acadêmico independente inspirado nos conceitos e guias públicos desses projetos. Veja [docs/08-referencias.md](docs/08-referencias.md) para o mapeamento.
