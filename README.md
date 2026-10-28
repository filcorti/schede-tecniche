# Schede tecniche di produzione — versione web

Consultazione delle schede tecniche e calcolo del costo tessuto, accessibile da
browser con accesso riservato. I dati stanno su Supabase, le pagine su Netlify,
il codice su GitHub.

## File in questa cartella

| File | A cosa serve |
|---|---|
| `index.html` | l'applicazione: accesso, dashboard, ricerca, scheda tecnica, calcolo costo, aggiornamento archivio |
| `config.js` | i due dati del tuo progetto Supabase — **da compilare** |
| `schema.sql` | la struttura del database, da eseguire una volta sola |
| `storico.sql` | la tabella dello storico valutazioni, da eseguire una volta sola |
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

## Lo storico delle valutazioni

Nella vista **Calcolo costo**, sotto al calcolo, c'è lo storico dell'articolo.
Il riquadro *Salva nello storico* in alto a destra prende data e nota e registra
la valutazione: i quattro numeri più la composizione congelata di quel giorno —
ogni filato col suo peso e il suo prezzo, calo, orditura, tessitura, finissaggi,
divisore.

Ogni riga si apre e mostra quella composizione, con due pulsanti: *Ricarica
questi valori*, che li rimette nel calcolo senza salvare niente, e *Elimina*,
che chiede conferma al secondo clic.

Lo storico sta nella tabella `valutazioni`, **separata da `schede`**. È
deliberato: *Aggiorna archivio* svuota `schede` e la ricarica dall'Excel, e se lo
storico stesse lì dentro sparirebbe al primo allineamento.

Due cose da sapere. Lo storico è **condiviso**: lo vedono, e possono
modificarlo, tutti quelli che entrano — mentre i prezzi che scrivi nel pannello,
finché non salvi, restano solo nel tuo browser. E le valutazioni vecchie
conservano i **pesi di allora**: se un domani l'Excel cambia i pesi di un
articolo, confrontando due righe lontane potresti confrontare due tessuti un po'
diversi. I pesi si vedono nel dettaglio, quindi te ne accorgi.

In stampa lo storico non esce: sull'A4 va il calcolo.

## La dashboard

Dopo l'accesso non si entra direttamente nella ricerca, ma in una pagina con un
riquadro per ogni vista: oggi **Scheda tecnica** e **Calcolo costo**. Si sceglie
il riquadro, si lavora, e col pulsante *← Dashboard* in alto si torna indietro
per cambiare vista.

Tutte le viste leggono lo stesso archivio: non ci sono dati diversi dietro i
riquadri, cambia solo come li vedi.

**Aggiungere una vista nuova.** Dentro `index.html`, nella sezione *le viste
della dashboard*, c'è l'elenco `VISTE`: una voce per riquadro, con nome, icona e
descrizione. Si aggiunge la voce e la funzione che disegna quella vista dentro
`disegna()`. Il resto della pagina non va toccato.

**Dare viste diverse a persone diverse** si potrà fare più avanti: nel codice
c'è già la funzione `visteConsentite()`, che oggi restituisce tutto e domani
leggerà da una tabella dei permessi su Supabase. Da tenere presente fin d'ora:
nascondere un riquadro **non protegge i dati**, perché tutte le viste leggono la
stessa tabella e chi se ne intende può arrivarci lo stesso. Se un giorno ci
saranno dati davvero riservati — i costi, per esempio — vanno separati in
un'altra tabella con le sue policy.

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
