# 01 — Comprovar acesso somente via VPN

Substitua `IP_PUBLICO_FRONTEND` e `IP_PRIVADO_FRONTEND` pelos endereços atuais da instância antes de executar os exemplos. Não os deixe preenchidos com valores reais em versões públicas desta documentação.

## Objetivo

Demonstrar que o IP público não entrega a aplicação a quem está fora da VPN, enquanto o aluno conectado ao OpenVPN acessa a Frontend pelo IP privado.

## Preparação

1. Confirme que o laboratório AWS está iniciado.
2. Conecte o perfil de cliente OpenVPN fornecido pelo administrador. O endpoint usa `IP_PUBLICO_FRONTEND:1194/UDP`.
3. No Windows, confira se a rota foi instalada:

   ```powershell
   route print -4 | findstr IP_PRIVADO_FRONTEND
   ```

   A rota precisa encaminhar `IP_PRIVADO_FRONTEND/32` pela interface VPN.

## Prova fora da VPN

Desconecte o OpenVPN ou use um computador sem o perfil e abra:

```text
https://IP_PUBLICO_FRONTEND
```

Resultado esperado: `403 Forbidden`. A mesma política se aplica a `/api/healthz`. O caminho ACME `/.well-known/acme-challenge/` permanece acessível para a renovação do certificado, mas não serve a aplicação.

Opcionalmente, no PowerShell:

```powershell
curl.exe -i https://IP_PUBLICO_FRONTEND/
curl.exe -i https://IP_PUBLICO_FRONTEND/api/healthz
```

## Prova pela VPN

Reconecte o perfil e abra:

```text
http://IP_PRIVADO_FRONTEND
```

Resultado esperado: tela de login. Verifique também a saúde da API:

```powershell
curl.exe -i http://IP_PRIVADO_FRONTEND/api/healthz
```

Resultado esperado: HTTP `200` e `{"status":"ok"}`.

## Explicação curta

O Nginx da Frontend permite somente clientes da faixa OpenVPN `VPN_CIDR`. O cliente VPN recebe uma rota específica para o IP privado da Frontend. O HTTP usado pelo navegador fica dentro do túnel criptografado; acessos públicos diretos recebem `403`.

## Estado da validação

Em 25/11/2026, o computador conectado recebeu a rota privada. A página e `/api/healthz` retornaram `200` pelo IP privado; o endereço público permaneceu bloqueado com `403`.
