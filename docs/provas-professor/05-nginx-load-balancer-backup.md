# 05 — Nginx, balanceamento e servidor backup

## Estado atual: preparação versionada, ativação pendente

O Nginx da Frontend está restrito à VPN e encaminha `/api` para a Backend 1 (`172.31.30.150`). Em 25/11/2026, a Backend 2 (`172.31.29.33`) e Backup (`172.31.27.244`) foram inspecionadas por SSH: ambas têm Nginx ativo na configuração padrão, sem Docker e sem a aplicação. A API responde saudável na Backend 1. A porta PostgreSQL ainda não está publicada no host.

Foram adicionados `deploy/compose.replica.yaml`, `deploy/setup-api-replica.sh` e `deploy/enable-nginx-lb.sh`. O script do balanceador recusa a troca enquanto os três endpoints de saúde não responderem `200`; assim, não aponta o site para páginas padrão ou serviços desligados. O repositório agora também contém o Compose base `compose.yaml`.

Antes de ativar: preparar os dois nós com o código e os três segredos iguais aos da Backend 1; publicar PostgreSQL somente no IP privado da Backend 1; e restringir a regra de entrada `TCP/5432` no Security Group da Backend 1 aos Security Groups da Backend 2 e Backup. Não use `0.0.0.0/0`. Os IPs privados observados são Backend 1 `172.31.30.150`, Backend 2 `172.31.29.33`, Backup `172.31.27.244`; confirme-os no momento da implantação.

Os uploads ainda ficam em volumes Docker locais. A API pode ler metadados e sessões no banco compartilhado, mas download de arquivos enviados por outro nó requer armazenamento de arquivos compartilhado ou replicado. Até resolver esse ponto, teste failover com `/api/healthz`, login e dados do PostgreSQL; não prometa recuperação de arquivos através de qualquer nó.

## Prova que será executada quando o upstream estiver pronto

1. Confirme que cada proxy responde `200` antes de ativar o upstream:

   ```bash
   for ip in 172.31.30.150 172.31.29.33 172.31.27.244; do
     curl -fsS -H 'Host: api.dadoseguro.internal' "http://${ip}/api/healthz"
   done
   ```

2. Na Frontend, execute `sudo bash enable-nginx-lb.sh 172.31.30.150 172.31.29.33 172.31.27.244 10.8.0.0/24` depois de copiar o script. Ele mantém a lista de acesso VPN e faz backup da configuração.
3. Mostre `sudo nginx -T` e confirme Backend 1/2 como destinos normais e Backup marcado com `backup`.
4. Pela VPN, faça várias chamadas a `https://23.22.200.189/api/healthz`. Observe `/var/log/nginx/access.log` em Backend 1 e 2 para demonstrar distribuição.
5. Na Backend 1, pare somente a API: `sudo docker compose -f /opt/dado-seguro/compose.yaml -f /opt/dado-seguro/deploy/compose.application.yaml stop api`. Faça chamadas repetidas e confirme resposta pela Backend 2.
6. Inicie a API da Backend 1 com o mesmo par de arquivos e `up -d api`. Depois pare a API nas duas primárias (na Backend 2 use `sudo docker compose --env-file /opt/dado-seguro/.env -f /opt/dado-seguro/deploy/compose.replica.yaml stop api`), sem parar PostgreSQL nem remover volumes. Aguarde `fail_timeout` (5 s) e confirme que a API responde pelo nó Backup.
7. Inicie novamente as duas APIs primárias usando `up -d api`. Confirme que elas recebem o tráfego e Backup volta a ficar em espera.
8. Mostre `docker compose ps`, logs dos três Nginx e a rota pública ainda bloqueada fora da VPN.

## Comandos de inspeção previstos

Comandos para inspeção após preparar os três nós:

```bash
sudo nginx -t
sudo nginx -T | sed -n '/upstream dadoseguro_api/,/}/p'
sudo tail -n 50 /var/log/nginx/access.log
sudo docker compose -f /opt/dado-seguro/compose.yaml \
  -f /opt/dado-seguro/deploy/compose.application.yaml ps
```

O endereço do backup no bloco `upstream` precisa usar a palavra-chave Nginx `backup`; caso contrário, esse nó também recebe tráfego normal e não comprova failover.

## Dependências técnicas

- O arquivo `.env` da Backend 1 deve definir `DADOSEGURO_DB_BIND_IP=172.31.30.150`; então recrie apenas o serviço `db` preservando o volume. A publicação fica vinculada ao IP privado, nunca a `0.0.0.0`.
- No Security Group da Backend 1, permita `TCP/5432` somente com origem nos Security Groups da Backend 2 e Backup. Confirme as regras de saída e a conectividade dos dois nós.
- Transfira `.db_password`, `.admin_password` e `.session_secret` da Backend 1 para `/opt/dado-seguro` em cada réplica por SSH; mantenha permissão de leitura necessária ao Docker e diretório raiz restrito.
- Copie `backend/`, `deploy/compose.replica.yaml` e `deploy/nginx-backend-api.conf.example` para `/opt/dado-seguro` em cada réplica. Em seguida, execute `sudo bash /opt/dado-seguro/deploy/setup-api-replica.sh 172.31.30.150`.
- Só depois dos três checks saudáveis execute `enable-nginx-lb.sh` na Frontend.
- Os volumes `uploads_data` dos nós não são compartilhados. Para validar downloads em failover, configure armazenamento compartilhado/replicado antes da apresentação.
