-- =====================================================================
--  Schede tecniche di produzione — struttura del database
--  Da eseguire una volta sola in Supabase:  SQL Editor  →  incolla  →  Run
-- =====================================================================

-- 1. La tabella ---------------------------------------------------------
--    I quattro campi su cui si cerca sono colonne vere e indicizzate.
--    Tutto il resto (le altre ~314 colonne del MODELLO) sta in 'dati',
--    cosi' se domani aggiungi un campo non devi toccare la struttura.
create table if not exists public.schede (
  id           bigserial primary key,
  id_record    text,                       -- "ID record" del MODELLO
  articolo     text not null,
  altezza      text not null,
  colore       text not null,
  descrizione  text,
  dati         jsonb not null default '{}'::jsonb,
  aggiornato   timestamptz not null default now()
);

create index if not exists schede_articolo_idx on public.schede (articolo);
create index if not exists schede_ricerca_idx  on public.schede (articolo, altezza, colore);
create index if not exists schede_descr_idx    on public.schede using gin (to_tsvector('italian', coalesce(descrizione,'')));

-- 2. Chi puo' leggere e scrivere ---------------------------------------
--    Nessun accesso anonimo: solo utenti autenticati.
alter table public.schede enable row level security;

drop policy if exists "lettura utenti autenticati" on public.schede;
create policy "lettura utenti autenticati"
  on public.schede for select
  to authenticated
  using (true);

drop policy if exists "scrittura utenti autenticati" on public.schede;
create policy "scrittura utenti autenticati"
  on public.schede for all
  to authenticated
  using (true) with check (true);

-- 3. Registrazione autonoma disattivata --------------------------------
--    Gli utenti li crei tu da  Authentication → Users → Add user.
--    Poi: Authentication → Providers → Email → "Allow new users to sign up" OFF.
--    L'aggiornamento dell'archivio lo fa la pagina stessa: svuota la tabella
--    e la ricarica a blocchi, mostrando l'avanzamento.
