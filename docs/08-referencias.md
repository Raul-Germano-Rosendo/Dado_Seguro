# 8. Referências e decisões

## Repositórios de orientação

1. **Kitsune Infrastructure**, de Raphaela Monteiro: https://github.com/raphaelamonteiro/kitsune-infrastructure. Referência conceitual para EC2, VPN WireGuard, SSH, Nginx, HAProxy, Docker/Compose e PostgreSQL.
2. **AWS Network Infrastructure for Deployment of WebApps**, de Ivan Duarte: https://github.com/Ivan-Duarte/AWS-Network-Infrastructure-for-Deployment-of-WebApps. Referência para EC2, VPN OpenVPN, Nginx/proxy reverso, CORS, diagramas e exemplos.

## Mapeamento

| Tema | Referência | Registro no Dado Seguro |
|---|---|---|
| EC2 e acesso | Ambas | `docs/03-aws-ec2.md` |
| VPN | OpenVPN no guia Ivan; WireGuard no Kitsune | `docs/04-rede-vpn.md`; Dado Seguro utilizou OpenVPN |
| Certificados | EasyRSA utilizado pelo aluno | `docs/04a-certificados-easyrsa.md`; sem chaves ou certificados reais |
| Proxy e web | Nginx em ambas; HAProxy no Kitsune | `docs/05-nginx.md` |
| CORS | Guia Ivan e Kitsune | `docs/06-seguranca.md`; aguarda URLs/API |
| Aplicação e persistência | Kitsune inclui frontend/backend/PostgreSQL/Docker | Planejados, não implementados |

## Autoria e licença

Este material organiza documentação própria a partir de conceitos e referências públicas, sem copiar arquivos de configuração dos projetos citados. Antes de reutilizar código/conteúdo de terceiros, confira as licenças e preserve créditos. O repositório de Ivan declara MIT; confirme no original os termos aplicáveis ao material que pretender reutilizar.
