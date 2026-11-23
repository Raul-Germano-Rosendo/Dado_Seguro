# Dado Seguro

Documentação de infraestrutura e planejamento técnico do projeto acadêmico **Dado Seguro**.

> **Estado atual:** o frontend React/Vite está no repositório e tem modo de demonstração com dados fictícios. Em 23/11/2026, Docker e PostgreSQL 16 foram instalados em uma instância backend; o banco ainda não tem a API nem o esquema funcional. Consulte [Estado da implantação](docs/09-estado-implantacao.md) e [Deploy com Docker e PostgreSQL](docs/10-deploy-docker-postgresql.md) para o estado confirmado e os próximos passos.

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
- [Deploy com Docker e PostgreSQL](docs/10-deploy-docker-postgresql.md)
- [Configurações de exemplo](config/README.md)

## Árvore do repositório

```text
Redes_Jean/
├── README.md
├── .gitignore
├── frontend/ (interface React/Vite)
├── deploy/ (script de instalação do backend e PostgreSQL)
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

O frontend usa `VITE_USE_MOCK=true` para demonstrar o fluxo sem API ou banco conectado. O contrato esperado da API está em `frontend/src/services/api.ts`; o modo mock não persiste dados após reiniciar a página.

## Referências usadas

- [Kitsune Infrastructure](https://github.com/raphaelamonteiro/kitsune-infrastructure)
- [AWS Network Infrastructure for Deployment of WebApps](https://github.com/Ivan-Duarte/AWS-Network-Infrastructure-for-Deployment-of-WebApps)

Este é material acadêmico independente inspirado nos conceitos e guias públicos desses projetos. Veja [docs/08-referencias.md](docs/08-referencias.md) para o mapeamento.
