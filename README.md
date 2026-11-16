# Dado Seguro

Documentação de infraestrutura e planejamento técnico do projeto acadêmico **Dado Seguro**.

> **Estado atual:** este repositório documenta a base estudada e fornece modelos de configuração. Frontend, banco de dados e Docker ainda não foram implementados. Os exemplos AWS/VPN são modelos: não contêm credenciais, chaves, endereços reais nem comprovam implantação ativa.

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
- [Configurações de exemplo](config/README.md)

## Árvore do repositório

```text
Redes_Jean/
├── README.md
├── .gitignore
├── docs/ (guias segmentados por assunto)
└── config/
    ├── aws/ (EC2 e regras de rede)
    ├── nginx/ (proxy reverso)
    └── vpn/ (modelos OpenVPN)
```

Leia primeiro `docs/` e `config/README.md`. Os arquivos `.example` são modelos para adaptação. Nunca versione chaves privadas, senhas, tokens ou dados pessoais.

## Referências usadas

- [Kitsune Infrastructure](https://github.com/raphaelamonteiro/kitsune-infrastructure)
- [AWS Network Infrastructure for Deployment of WebApps](https://github.com/Ivan-Duarte/AWS-Network-Infrastructure-for-Deployment-of-WebApps)

Este é material acadêmico independente inspirado nos conceitos e guias públicos desses projetos. Veja [docs/08-referencias.md](docs/08-referencias.md) para o mapeamento.
