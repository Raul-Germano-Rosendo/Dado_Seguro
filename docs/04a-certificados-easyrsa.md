# 4A. Certificados OpenVPN com EasyRSA

## Uso no Dado Seguro

O projeto utilizou EasyRSA para gerar e administrar a infraestrutura de chave pública (PKI) necessária aos certificados do OpenVPN. A configuração exata depende da versão instalada e do ambiente; este guia organiza o processo sem afirmar que os comandos abaixo foram executados exatamente desta forma.

EasyRSA cria e administra a CA e os certificados. A chave privada da CA é altamente sensível: mantenha-a protegida e, sempre que possível, fora da instância VPN. Cada cliente deve ter identidade/certificado próprio para permitir revogação individual.

## Fluxo de trabalho

1. Instalar EasyRSA em ambiente controlado e inicializar um diretório PKI dedicado.
2. Definir os parâmetros da CA antes de criá-la; `config/vpn/easyrsa-vars.example` é apenas um modelo de identificação.
3. Criar a CA e proteger sua chave privada com acesso restrito e backup seguro.
4. Gerar solicitação e certificado para o servidor com uso de servidor TLS; assinar com a CA.
5. Gerar solicitação e certificado separado para cada cliente; assinar com a CA.
6. Instalar no servidor os certificados/chaves exigidos pela configuração OpenVPN e distribuir ao cliente somente os arquivos necessários.
7. Em caso de perda ou desligamento de cliente, revogar seu certificado e atualizar a lista de revogação (CRL) utilizada pelo servidor.
8. Fazer backup protegido da PKI, documentar validade/renovação e testar a revogação.

Os nomes de comandos e opções variam entre versões do EasyRSA. Consulte a documentação da versão efetivamente instalada antes de executar os passos. Não copie uma CA ou chave privada de um ambiente de teste para produção.

## Organização sugerida dos materiais

```text
PKI EasyRSA (fora do Git)
├── CA privada e chave da CA (acesso muito restrito)
├── certificados e chaves do servidor
├── certificados e chaves individuais dos clientes
└── CRL e registros de emissão/revogação
```

No repositório do projeto, mantenha somente instruções e templates. Não versione a pasta `pki/`, chaves `.key`, certificados de cliente, perfis `.ovpn` preenchidos ou arquivos contendo credenciais. O `.gitignore` inclui extensões comuns, mas revise o conteúdo antes de cada commit.

## Modelo de parâmetros

`config/vpn/easyrsa-vars.example` contém somente campos descritivos para a CA. Personalize antes de inicializar uma PKI; parâmetros de identidade não são segredos, mas devem refletir o projeto. Não inclua senhas nem material criptográfico nesse arquivo.
