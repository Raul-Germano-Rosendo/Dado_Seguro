# Modelos de configuração

Todos os arquivos desta pasta são exemplos didáticos, não configurações validadas para conta, host ou domínio reais. Revise e substitua placeholders antes de usar.

| Caminho | Uso | Atenção |
|---|---|---|
| `aws/ec2-user-data.sh` | Bootstrap mínimo em Amazon Linux | Validar AMI; não contém app |
| `aws/security-group.example.json` | Inventário legível de regras | Não é importação AWS direta; restrinja origens |
| `vpn/*.conf.example` | Estrutura OpenVPN para servidor e cliente | Use certificados válidos; proteja chaves e perfil cliente |
| `vpn/easyrsa-vars.example` | Modelo de parâmetros identificadores da PKI | Não armazena chaves nem certificados |
| `nginx/dado-seguro.conf.example` | Proxy HTTP para upstream futuro | Não é produção; configure DNS e TLS |

Nunca versione chaves privadas, certificados, senhas, tokens, credenciais AWS ou perfis de cliente VPN preenchidos. `.gitignore` ajuda, mas não substitui revisão do commit.
