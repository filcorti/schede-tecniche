# Schede tecniche di produzione — versione web

Consultazione delle schede tecniche e calcolo del costo tessuto, accessibile da
browser con accesso riservato. I dati stanno su Supabase, le pagine su Netlify,
il codice su GitHub.

## File in questa cartella

| File | A cosa serve |
|---|---|
| `index.html` | l'applicazione: accesso, ricerca, scheda, calcolo costo, aggiornamento archivio |
| `config.js` | i due dati del tuo progetto Supabase — **da compilare** |
| `schema.sql` | la struttura del database, da eseguire una volta sola |
| `netlify.toml` | impostazioni di pubblicazione |

---

## 1. Supabase — il database

1. Su [supabase.com](https://supabase.com) crea un progetto nuovo. Scegli la
   regione europea (Frankfurt o Ireland): i dati restano in Europa e il sito
   risponde più in fretta.
2. Apri **SQL Editor**, incolla tutto il contenuto di `schema.sql`, premi **Run**.
   Crea la tabella, gli indici e le regole di accesso.
3. Vai in **Authentication → Providers → Email** e metti su **OFF** la voce
   *"Allow new users to sign up"*. Così nessuno può registrarsi da solo.
4. Vai in **Authentication → Users → Add user** e crea un utente per ogni persona
   che deve entrare: indirizzo email e password. Spunta *Auto Confirm User*.
5. Vai in **Project Settings → API** e copia due cose:
   - **Project URL** (tipo `https://abcdefgh.supabase.co`)
   - la chiave **anon / public**

## 2. config.js — collegare le pagine al database

Apri `config.js` e incolla i due valori al posto dei segnaposto.

Quella chiave è fatta per stare lì: da sola non dà accesso a niente, perché le
regole del database (punto 2 dello `schema.sql`) pretendono un utente
autenticato. Senza login non esce nemmeno una riga.

## 3. GitHub — il codice

1. Crea un repository **privato**.
2. Carica i quattro file: `index.html`, `config.js`, `schema.sql`, `netlify.toml`.
   Si fa dal sito di GitHub, con *Add file → Upload files*, trascinandoli.

## 4. Netlify — la pubblicazione

1. Su [netlify.com](https://netlify.com): *Add new site → Import an existing project*,
   scegli GitHub e il repository appena creato.
2. Non serve impostare niente: build command vuoto, publish directory `.`
   (lo dice già `netlify.toml`).
3. Netlify ti dà un indirizzo tipo `qualcosa.netlify.app`. Puoi rinominarlo in
   *Site settings → Change site name*.

Il piano gratuito basta: la protezione non la fa Netlify, la fa Supabase.

## 5. Primo caricamento dei dati

1. Apri l'indirizzo del sito, entra con uno degli utenti creati.
2. Premi **Aggiorna archivio** in alto.
3. Scegli il file `FILEMAKER_2026_modello_calcoli.xlsx`.
4. Aspetta la barra. Legge il foglio **MODELLO** e carica tutte le schede.
   Dura qualche minuto: cinquemila schede da mandare su internet.

## 6. Quando aggiorni l'archivio

Stessa cosa: lavori sull'Excel come sempre, poi quando vuoi allineare il sito
entri, premi **Aggiorna archivio** e scegli il file. Non serve toccare GitHub
né Netlify.

**Attenzione:** l'operazione sostituisce tutte le schede. Per il minuto in cui
sta caricando, l'archivio online è incompleto. Fallo quando i colleghi non
stanno consultando.

---

## Cose da sapere

**Chi può entrare.** Solo gli utenti che crei tu in Supabase. Nessuno può
registrarsi, e chi arriva sull'indirizzo senza credenziali vede soltanto la
schermata di accesso.

**Il progetto gratuito di Supabase va in pausa** dopo circa una settimana senza
attività: la prima apertura dopo una pausa è lenta finché non si risveglia. Con
un uso quotidiano non succede.

**L'Excel resta il padrone.** Il sito è una copia allineata da te. Le modifiche
si fanno sull'Excel, non online: se modificassi i dati nel database, al
successivo aggiornamento verrebbero sovrascritti.

**La stampa** funziona come nei file locali: il pulsante *Stampa* manda in A4 la
vista che stai guardando, scheda o calcolo costo.

**Se cambi la struttura dell'Excel** aggiungendo colonne nuove, non devi fare
niente: finiscono automaticamente nel database, perché i campi stanno in una
colonna JSON. Le pagine mostreranno i campi nuovi solo se glielo chiedi.
