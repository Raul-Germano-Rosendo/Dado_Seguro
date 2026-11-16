# 4. Rede e VPN

## Finalidade

A VPN oferece um caminho privado para administração ou comunicação entre nós autorizados. Ela não substitui firewall, autenticação forte, atualizações nem HTTPS para a aplicação.

## Escolha de tecnologia

O repositório de Ivan apresenta OpenVPN (servidor e cliente), e o Kitsune descreve WireGuard entre instâncias. No Dado Seguro foi utilizado OpenVPN. Os arquivos em `config/vpn/` são modelos OpenVPN explicativos, com endereços e certificados placeholders; substitua-os pelas configurações reais do ambiente, sem publicar chaves privadas.

## Endereçamento e regras

Use a faixa privada configurada no servidor OpenVPN e confirme que não conflita com VPC, rede doméstica, acadêmica ou outra VPN. Defina rotas mínimas para os recursos que os clientes precisam acessar. O arquivo de exemplo usa UDP e porta ilustrativa; confirme protocolo e porta efetivamente utilizados. Permita o tráfego no Security Group e no firewall do host apenas para o endpoint VPN. Não habilite encaminhamento global sem requisito.

## Chaves

Os certificados usados pelo OpenVPN foram gerenciados com EasyRSA. Consulte [Certificados com EasyRSA](04a-certificados-easyrsa.md) para o fluxo e o modelo de variáveis. Proteja a chave privada e certificados do servidor e de cada cliente. Nunca publique arquivos `.key`, credenciais ou perfis cliente completos em commits. Distribua perfis por canal confiável, revogue certificados/perfis perdidos e faça rotação quando necessário.

Os arquivos em `config/vpn/` são esqueletos didáticos: substitua placeholders, instale certificados válidos e revise rotas, TLS e firewall antes de usar. Não os aplique diretamente.
