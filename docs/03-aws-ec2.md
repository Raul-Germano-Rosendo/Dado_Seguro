# 3. AWS e EC2

## Planejamento

1. Escolher região e confirmar custos, limites e disponibilidade.
2. Criar VPC e planejar CIDRs sem sobreposição com rede local e faixa VPN.
3. Definir sub-redes públicas/privadas conforme os componentes necessários.
4. Escolher AMI suportada, tamanho de instância e armazenamento apropriados.
5. Usar IAM com privilégio mínimo; não manter chaves de acesso permanentes na instância.
6. Criar Security Groups com origem restrita e revisar IPv4 e IPv6.
7. Definir atualização, logs, backup e encerramento de recursos.

## Acesso administrativo

- Preferir Session Manager ou VPN quando configurados.
- Se SSH for necessário, permitir TCP/22 apenas de IP/CIDR administrativo conhecido. Não usar `0.0.0.0/0` em ambiente público.
- Guardar chave privada fora do Git, limitar permissões locais e evitar login direto como root.

## Modelos

`config/aws/ec2-user-data.sh` é um exemplo para Amazon Linux 2023; atualiza pacotes e instala ferramentas básicas, sem instalar a aplicação. `config/aws/security-group.example.json` documenta regras, não é importação direta do EC2. Adapte as regras na AWS e use origem mínima.

## Custos

EC2, volumes, IPv4 público, transferência e outros serviços podem gerar cobrança. Use tags como `Projeto=DadoSeguro` e `Ambiente=estudo`, monitore custos e encerre recursos de laboratório ao terminar. Verifique volumes e snapshots remanescentes.
