-- ===========================================================
--  BOLÃO BRASILEIRÃO — esquema do banco (rode no SQL Editor do Supabase)
-- ===========================================================

-- Tabela de palpites: um registro por jogador
create table if not exists palpites (
  nome        text primary key,
  dados       jsonb not null default '{}'::jsonb,
  atualizado  timestamptz not null default now()
);

-- Tabela de resultados oficiais: uma única linha (id = 1)
create table if not exists resultados (
  id          int primary key default 1,
  dados       jsonb not null default '{}'::jsonb,
  senha       text,
  atualizado  timestamptz not null default now()
);

-- Tabela de pagamentos: um registro por jogador
create table if not exists pagamentos (
  nome        text primary key,
  pago        boolean not null default false,
  atualizado  timestamptz not null default now()
);

-- ----------------------------------------------------------
--  Segurança (RLS)
-- ----------------------------------------------------------
-- Habilita Row Level Security nas duas tabelas
alter table palpites  enable row level security;
alter table resultados enable row level security;
alter table pagamentos enable row level security;

-- PALPITES: qualquer pessoa com o link pode ler e gravar o próprio palpite.
-- (Bolão entre amigos; a "trava" anti-trapaça fica nos resultados.)
create policy "palpites_leitura_publica"
  on palpites for select using (true);

create policy "palpites_escrita_publica"
  on palpites for insert with check (true);

create policy "palpites_update_publico"
  on palpites for update using (true) with check (true);

-- RESULTADOS: leitura liberada (todos veem o ranking);
-- a escrita é liberada na camada do banco, mas o APP exige a senha
-- (RESULTS_PASSWORD) antes de chamar o salvamento.
create policy "resultados_leitura_publica"
  on resultados for select using (true);

create policy "resultados_escrita_publica"
  on resultados for insert with check (true);

create policy "resultados_update_publico"
  on resultados for update using (true) with check (true);

-- PAGAMENTOS: leitura e escrita liberadas (bolão entre amigos, base na confiança)
create policy "pagamentos_leitura_publica"
  on pagamentos for select using (true);

create policy "pagamentos_escrita_publica"
  on pagamentos for insert with check (true);

create policy "pagamentos_update_publico"
  on pagamentos for update using (true) with check (true);

-- Linha inicial de resultados (vazia)
insert into resultados (id, dados) values (1, '{}'::jsonb)
  on conflict (id) do nothing;
