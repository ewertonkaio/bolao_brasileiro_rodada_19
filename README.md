# Bolão Brasileirão — Netlify + Supabase + Mercado Pago

Bolão da 19ª rodada com palpites, ranking, resultados e **pagamento Pix via Mercado Pago
com confirmação automática**.

São 4 etapas: **banco → Mercado Pago → deploy → variáveis**.

---

## 1. Supabase (banco de dados)

1. Projeto em https://supabase.com -> **SQL Editor** -> **New query**.
2. Cole todo o `supabase.sql` e clique em **Run** (cria `palpites`, `resultados`, `pagamentos`).
3. Em **Project Settings -> API**, anote:
   - **Project URL** (`https://xxxxx.supabase.co`)
   - **anon public** key (`eyJ...`)
   - **service_role** key (`eyJ...`) — secreta, usada só pelo webhook no servidor.

> A `service_role` da acesso total ao banco. Ela fica **so** nas variaveis do Netlify,
> nunca no codigo nem no navegador.

---

## 2. Mercado Pago (cobranca)

1. Acesse https://www.mercadopago.com.br/developers e faca login.
2. Crie uma aplicacao (**Suas integracoes -> Criar aplicacao**), tipo *Pagamentos online*.
3. Em **Credenciais de producao**, copie o **Access Token** (`APP_USR-...`).
   - Para testar antes, da pra usar as credenciais de **teste** primeiro.
4. Esse token vai como `MP_ACCESS_TOKEN` no Netlify.

> Para receber Pix, sua conta Mercado Pago precisa ter uma **chave Pix cadastrada**
> (em Seu negocio -> Pix). O QR gerado cai direto nessa conta.

---

## 3. Netlify (hospedagem + funcoes)

1. Suba todos os arquivos para um repositorio no GitHub, incluindo a pasta
   `netlify/functions/`.
2. No Netlify: **Add new site -> Import an existing project** -> conecte o repositorio.
3. O `netlify.toml` ja configura tudo:
   - Build command: `bash build.sh`
   - Publish directory: `.`
   - Functions directory: `netlify/functions`
4. Defina as variaveis (etapa 4) **antes** de publicar.

---

## 4. Variaveis de ambiente

No Netlify: **Site configuration -> Environment variables**.

| Chave | Valor | Onde e usada |
|-------|-------|--------------|
| `SUPABASE_URL` | Project URL do Supabase | app + webhook |
| `SUPABASE_ANON_KEY` | chave `anon public` | app (navegador) |
| `SUPABASE_SERVICE_KEY` | chave `service_role` (secreta) | webhook (servidor) |
| `RESULTS_PASSWORD` | senha a sua escolha | salvar resultados |
| `ENTRY_FEE` | valor da entrada, so numeros (ex: `10`) | cobranca |
| `MP_ACCESS_TOKEN` | Access Token do Mercado Pago (secreto) | funcoes de pagamento |

Depois clique em **Deploy**.

### Webhook
O endereco do webhook e:
`https://SEU-SITE.netlify.app/.netlify/functions/webhook-mp`

A funcao `criar-pagamento` ja informa esse endereco ao Mercado Pago a cada cobranca,
entao normalmente **nao precisa configurar nada manualmente**. Se quiser garantir,
cadastre o mesmo endereco em **Mercado Pago -> sua aplicacao -> Webhooks**, evento *Pagamentos*.

---

## Como funciona o pagamento

1. O jogador abre a aba **Pagar** e clica em **Gerar QR Code Pix**.
2. O app chama a funcao `criar-pagamento`, que cria a cobranca no MP e devolve o QR.
3. O jogador paga pelo banco. O MP avisa a funcao `webhook-mp`.
4. O webhook confirma o pagamento direto no MP (com o token secreto) e marca o
   jogador como **pago** no Supabase.
5. A tela detecta a confirmacao sozinha e o ranking mostra o selo **pago**.

> A confirmacao e checada de verdade no Mercado Pago — ninguem consegue se marcar
> como pago sem pagar.

---

## Testando

- Use as **credenciais de teste** do MP e os usuarios de teste para simular pagamentos
  antes de ir pra producao.
- Se aparecer "Banco de dados nao conectado": revise `SUPABASE_URL` / `SUPABASE_ANON_KEY`.
- Se o QR nao gera: revise `MP_ACCESS_TOKEN` e veja os logs em
  **Netlify -> Functions -> criar-pagamento**.
- Se o pagamento nao confirma sozinho: veja os logs de **webhook-mp** e confira a
  `SUPABASE_SERVICE_KEY`.

---

## Observacao (importante)

Bolao informal entre amigos, sem lucro do organizador, com todo o valor virando premio.
Isto nao e orientacao juridica — se for divulgar publicamente ou crescer, vale falar
com um advogado sobre as regras de apostas no Brasil.
