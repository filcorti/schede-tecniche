-- =====================================================================
--  Storico delle valutazioni di costo
--  Da eseguire UNA volta in Supabase:  SQL Editor  →  incolla  →  Run
--  Non tocca la tabella 'schede': le due vivono separate, ed e' il punto
--  che conta -- "Aggiorna archivio" svuota 'schede' e la ricarica
--  dall'Excel, mentre questa resta dov'e'.
-- =====================================================================

create table if not exists public.valutazioni (
  id          bigserial primary key,

  -- il legame con la scheda: la terna, non l'id, perche' gli id di
  -- 'schede' vengono riassegnati a ogni ricaricamento dall'Excel.
  articolo    text not null,
  altezza     text not null,
  colore      text not null,
  id_record   text,

  data        date not null default current_date,
  nota        text,
  utente      text,

  -- i quattro numeri in chiaro, per poterli cercare e ordinare senza
  -- frugare nel JSON (es. "tutte le valutazioni di ottobre").
  costo_ml    numeric,
  costo_mq    numeric,
  prezzo_ml   numeric,
  prezzo_mq   numeric,
  divisore    numeric,

  -- la fotografia completa: prezzi per filato, pesi, lavorazioni.
  dettaglio   jsonb not null default '{}'::jsonb,

  creata      timestamptz not null default now()
);

create index if not exists valutazioni_art_idx
  on public.valutazioni (articolo, altezza, colore, data desc, id desc);
create index if not exists valutazioni_data_idx
  on public.valutazioni (data desc);

-- Permessi: come per 'schede', l'esposizione automatica e' spenta.
grant usage on schema public to authenticated;
grant select, insert, update, delete on public.valutazioni to authenticated;
grant usage, select on sequence public.valutazioni_id_seq to authenticated;

-- Regole di riga: solo chi ha fatto l'accesso.
alter table public.valutazioni enable row level security;

drop policy if exists "lettura utenti autenticati" on public.valutazioni;
create policy "lettura utenti autenticati"
  on public.valutazioni for select
  to authenticated
  using (true);

drop policy if exists "scrittura utenti autenticati" on public.valutazioni;
create policy "scrittura utenti autenticati"
  on public.valutazioni for all
  to authenticated
  using (true) with check (true);
