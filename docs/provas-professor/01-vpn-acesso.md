# 01 — Comprovar acesso somente via VPN

## Objetivo

Demonstrar que o IP público não entrega a aplicação a quem está fora da VPN, enquanto o aluno conectado ao OpenVPN acessa a Frontend pelo IP privado.

## Preparação

1. Confirme que o laboratório AWS está iniciado.
2. Conecte `windows-client.ovpn` no cliente OpenVPN. O perfil aponta para `23.22.200.189:1194/UDP`.
3. No Windows, confira se a rota foi instalada:

   ```powershell
   route print -4 | findstr 172.31.30.175
   ```

   A rota precisa encaminhar `172.31.30.175/32` pela interface VPN.

## Prova fora da VPN

Desconecte o OpenVPN ou use um computador sem o perfil e abra:

```text
https://23.22.200.189
```

Resultado esperado: `403 Forbidden`. A mesma política se aplica a `/api/healthz`. O caminho ACME `/.well-known/acme-challenge/` permanece acessível para a renovação do certificado, mas não serve a aplicação.

Opcionalmente, no PowerShell:

```powershell
curl.exe -i https://23.22.200.189/
curl.exe -i https://23.22.200.189/api/healthz
```

## Prova pela VPN

Reconecte o perfil e abra:

```text
http://172.31.30.175
```

Resultado esperado: tela de login. Verifique também a saúde da API:

```powershell
curl.exe -i http://172.31.30.175/api/healthz
```

Resultado esperado: HTTP `200` e `{"status":"ok"}`.

## Explicação curta

O Nginx da Frontend permite somente clientes da faixa OpenVPN `10.8.0.0/24`. O cliente VPN recebe uma rota específica para o IP privado da Frontend. O HTTP usado pelo navegador fica dentro do túnel criptografado; acessos públicos diretos recebem `403`.

## Estado da validação

O bloqueio público foi testado do computador fora da VPN: HTTP, HTTPS e API retornaram `403`. A página e o health check responderam `200` pelo túnel `tun0` no próprio servidor. A conexão do perfil OpenVPN no computador Windows ainda precisa ser reconectada e conferida antes da apresentação.
