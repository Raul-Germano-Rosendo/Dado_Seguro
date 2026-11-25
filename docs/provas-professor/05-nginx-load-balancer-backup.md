# 05 — Nginx, balanceamento e servidor backup

## Estado atual: pendente

O Nginx da Frontend está restrito à VPN, mas o proxy atual encaminha `/api` para uma única Backend 1 (`172.31.30.150`). Backend 2 e a instância Backup ainda não foram adicionadas ao upstream da aplicação. Portanto, a prova de distribuição e failover ainda não deve ser apresentada como concluída.

O SSH na Backend 2 (`34.227.192.88`) expirou do computador e pela Frontend. Antes de configurar o upstream, ainda é necessário confirmar no console AWS os endereços privados, as regras dos Security Groups e o acesso administrativo aos nós. Não pare os serviços atuais enquanto isso estiver pendente.

## Prova que será executada quando o upstream estiver pronto

1. Mostre o bloco `upstream` ativo em `/etc/nginx/sites-available/dadosseguro`.
2. Consulte os health checks de Backend 1 e Backend 2 pela VPN e confirme que ambos estão saudáveis.
3. Faça várias chamadas a `/api/healthz` e observe nos logs dos nós primários que as requisições se distribuem.
4. Pare somente o container API de um primário, sem parar o PostgreSQL nem remover volumes.
5. Confirme que o Nginx continua servindo a API pelo outro primário.
6. Pare os containers API dos dois primários e confirme que o Nginx usa o servidor marcado como `backup`.
7. Inicie novamente os primários e confirme que o tráfego retorna a eles.
8. Mostre os logs do Nginx e o estado final dos containers.

## Comandos de inspeção previstos

Os comandos abaixo devem ser usados após documentar os nomes dos serviços e aplicar a configuração nos três nós:

```bash
sudo nginx -t
sudo nginx -T | sed -n '/upstream dadoseguro_api/,/}/p'
sudo tail -n 50 /var/log/nginx/access.log
sudo docker compose -f /opt/dado-seguro/compose.yaml \
  -f /opt/dado-seguro/deploy/compose.application.yaml ps
```

O endereço do backup no bloco `upstream` precisa usar a palavra-chave Nginx `backup`; caso contrário, esse nó também recebe tráfego normal e não comprova failover.

## Dependência técnica

Backend 2 e Backup precisam executar a API e acessar o mesmo banco persistente. A configuração deve limitar o PostgreSQL da Backend 1 à rede privada e permitir `5432` somente a partir dos nós autorizados. Não abra essa porta para `0.0.0.0/0`. Os arquivos enviados pela aplicação também precisam estar no volume correspondente do nó que atenderá cada download; essa parte deve ser resolvida antes de declarar a prova de failover completa.
