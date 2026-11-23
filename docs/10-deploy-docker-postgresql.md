# 10. Deploy simples com Docker e PostgreSQL

## Objetivo

Este deploy prepara uma instância Ubuntu para o backend do Dado Seguro: instala Docker Engine e Docker Compose pelo repositório oficial e sobe PostgreSQL 16 em contêiner com volume persistente. O procedimento é um único script: [`deploy/setup-backend.sh`](../deploy/setup-backend.sh).

O banco não publica a porta `5432` no host. Quando a API for adicionada ao mesmo Compose, ela deverá conectar ao banco pelo nome `db`, na porta `5432`. Assim, não é necessário liberar PostgreSQL no Security Group neste primeiro estágio.

## Estado implementado

Em 23/11/2026, a instância Backend 1 foi identificada como Ubuntu 26.04 LTS, sem Docker instalado e com Nginx ativo. Docker Engine `29.10.0` e Docker Compose `5.8.0` foram instalados. O contêiner `postgres:16` ficou `healthy`; `pg_isready` passou, a porta do banco não está publicada no host e os dados usam o volume Docker `dado-seguro_postgres_data`. O Nginx permaneceu ativo. Nenhuma outra instância, regra de Security Group ou rota AWS foi alterada.

O frontend React/Vite está no repositório e opera em modo de demonstração. Ainda não há código-fonte, Dockerfile ou imagem da API. Portanto, esta etapa instala Docker e o banco; a API será adicionada quando sua implementação estiver disponível. Não há credenciais no Git.

## Requisitos

- Ubuntu 22.04, 24.04 ou 26.04, acesso administrativo e saída HTTPS para os repositórios de pacotes e imagens.
- Espaço livre para a imagem e os dados. O perfil atual é de laboratório e baixa carga; uma `t3.micro` tem recursos limitados.
- O script deve ser executado na instância designada para a API e o banco. Outros servidores não compartilham automaticamente a rede privada do Compose.

## Instalação

No PowerShell, da raiz do repositório, copie o script e execute-o por SSH. Substitua o caminho da chave e o endereço pelo acesso atual da instância; não adicione a chave ao repositório.

```powershell
scp -i "C:\caminho\da-chave-backend.pem" .\deploy\setup-backend.sh ubuntu@IP_DA_INSTANCIA:/tmp/setup-backend.sh
ssh -i "C:\caminho\da-chave-backend.pem" ubuntu@IP_DA_INSTANCIA "sudo bash /tmp/setup-backend.sh"
```

O script também pode ser executado diretamente na instância:

```bash
sudo bash setup-backend.sh
```

O script instala Docker/Compose, cria `/opt/dado-seguro/compose.yaml`, gera uma senha aleatória em `/opt/dado-seguro/.db_password` com permissão somente para root e inicia o serviço `db`. A senha e os dados ficam fora do repositório.

O volume nomeado `postgres_data` preserva os dados quando o contêiner é recriado. Não use `docker compose down -v` em uma instância que contenha dados que queira manter: a opção `-v` remove o volume.

## Comandos de operação

Verificar estado e saúde (o diretório `/opt/dado-seguro` é acessível somente a root):

```bash
sudo docker compose -f /opt/dado-seguro/compose.yaml ps
sudo docker compose -f /opt/dado-seguro/compose.yaml logs --tail=100 db
sudo docker compose -f /opt/dado-seguro/compose.yaml exec -T db pg_isready -U dadoseguro_app -d dadoseguro
```

Reiniciar o serviço sem apagar os dados:

```bash
sudo docker compose -f /opt/dado-seguro/compose.yaml restart db
```

Criar um dump lógico em arquivo compactado, protegido no diretório home do usuário atual:

```bash
ARQUIVO="$HOME/dadoseguro-$(date +%F-%H%M).sql.gz"
sudo docker compose -f /opt/dado-seguro/compose.yaml exec -T db \
  pg_dump -U dadoseguro_app -d dadoseguro | gzip > "$ARQUIVO"
chmod 600 "$ARQUIVO"
```

Copie os dumps para armazenamento separado, por exemplo um bucket S3 privado com criptografia e retenção definida. Um volume local ou uma instância chamada “Backup” não substituem uma cópia externa nem um teste de restauração.

Para restaurar um dump SQL em um banco vazio ou preparado para restauração (importar em um banco com tabelas existentes pode gerar conflitos ou duplicar registros; confirme o destino antes):

```bash
gzip -dc "$ARQUIVO" | sudo docker compose -f /opt/dado-seguro/compose.yaml \
  exec -T db psql -U dadoseguro_app -d dadoseguro
```

## Conexão da API

Quando o código da API e seu Dockerfile existirem, adicione o serviço `api` ao `compose.yaml` e mantenha-o na rede padrão deste projeto Compose. Parâmetros de conexão esperados:

| Configuração | Valor |
|---|---|
| Host do banco | `db` |
| Porta | `5432` |
| Banco | `dadoseguro` |
| Usuário da aplicação | `dadoseguro_app` |
| Senha | Ler o secret em `/run/secrets/db_password` |

Não grave a senha no código, Dockerfile, histórico do shell ou Git. O Compose local monta secrets como arquivos; conceda acesso ao secret somente aos serviços que precisam dele.

Se a API for colocada em outra instância, ela não alcançará o nome `db`. Isso exige expor o banco somente pelo IP privado do host e limitar `TCP/5432` no Security Group à origem backend autorizada. Este script deliberadamente não abre essa porta; revise a rede e as regras atuais antes de adotar o modo multi-host.

## Limites e próximos passos

- O PostgreSQL é um único nó, sem alta disponibilidade. Esta é uma configuração didática para começar.
- O volume mantém dados no disco da instância, mas não protege contra perda da instância ou do volume.
- A aplicação ainda precisa ser implementada, receber Dockerfile/Compose, testes, migrações e configuração segura de segredos.
- Antes de uso real, planeje backup externo e teste de restauração, atualização de imagens, monitoramento, TLS e capacidade. Avalie RDS se administração e recuperação gerenciadas forem prioridade.

## Referências oficiais

- [Instalar Docker Engine no Ubuntu](https://docs.docker.com/engine/install/ubuntu/)
- [Docker Compose em produção](https://docs.docker.com/compose/how-tos/production/)
- [Secrets no Docker Compose](https://docs.docker.com/compose/how-tos/use-secrets)
- [Acesso privado ao Amazon RDS](https://docs.aws.amazon.com/AmazonRDS/latest/gettingstartedguide/security-public-private.html)
