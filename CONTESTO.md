# Contesto del progetto — per chi riprende il codice

Questo file non spiega *come si usa* l'applicazione (quello sta nel `README.md`):
spiega **com'è fatta dentro, perché è fatta così, e dove sono le trappole**.
Serve a una persona che subentra o a un assistente che legge il repository.

---

## 1. Cos'è

Manifattura Corti (Barzanò, tessuti tecnici in acrilico tinto in massa) teneva
l'archivio delle schede tecniche di produzione in FileMaker e poi in un Excel,
`FILEMAKER_2026_modello_calcoli.xlsx`: **318 colonne per circa 5.189 schede**.
Questa applicazione porta quell'archivio sul web, in sola lettura per i dati
tecnici, e ci aggiunge il **calcolo del costo** del tessuto e lo **storico delle
valorizzazioni**.

L'Excel resta il padrone: si lavora lì e si riallinea il sito con *Aggiorna
archivio*, che **svuota e ricarica** la tabella `schede`.

---

## 2. Com'è costruita

Nessun framework, nessuna build, nessuna dipendenza da installare.

- **`index.html`** è l'applicazione intera: HTML, CSS e JavaScript in un file
  solo. JavaScript in stile ES5 (`var`, `function`, niente moduli), perché deve
  funzionare ovunque senza transpilazione.
- **`config.js`** contiene soltanto `window.CONFIG = { url, key }` di Supabase.
  È separato apposta: il resto del codice non cambia fra un ambiente e l'altro.
- Da CDN arrivano solo `@supabase/supabase-js` (UMD) e `xlsx` per leggere il
  file Excel nel browser.
- **`sw.js`** è il service worker che rende l'app installabile.
- Pubblicazione: push su `main` → Netlify pubblica la cartella così com'è.

### Convenzioni di scrittura

- **Nomi e commenti in italiano**, come il dominio.
- I commenti spiegano **il perché**, non il cosa: se una riga è strana, accanto
  c'è il motivo per cui è strana.
- Grafica **Material 3 Expressive, solo tema chiaro** (nessun tema scuro: scelta
  esplicita). Le variabili colore stanno in `:root`.
- Punti di rottura: **≥1181px** scrivania a tutta altezza, **≤1180px** ripiego a
  colonne impilate, **≤860px** tablet, **≤760px** telefono.

---

## 3. I dati

### Tabella `schede` (vedi `schema.sql`)

`id, id_record, articolo, altezza, colore, descrizione, dati jsonb, aggiornato`

Le 318 colonne dell'Excel finiscono **tutte dentro `dati`**, con le intestazioni
originali come chiavi. Aggiungere colonne all'Excel non richiede modifiche al
database. I nomi sono quelli, con le loro stranezze, e il codice li usa testuali:

| chiave in `dati` | cos'è |
|---|---|
| `Articolo`, `Altezza`, `Colore`, `ID record` | identificano la scheda |
| `ord` | peso dell'ordito in g/m |
| `Tra 100` | peso della trama in g/m |
| `gr1` … `gr10` | peso di ogni singolo filato — **vedi sotto** |
| `codifica filato`, `codifica filato2`…`codifica filato 12` | i codici dei filati |
| `imborso` | percentuale di imborso |
| `battute` / `batt.cm fin cap` | battute al cm |
| `h fin cap` | altezza finita in cm (serve per il €/m²) |
| `g m totale`, `laura` | pesi totali g/m e g/m² |
| `£ o`, `£ t`, `£ battuta`, `Finiss` | vecchi prezzi FileMaker **in lire**, solo informativi |
| `Costo TOT.`, `Divisore 86` | vecchi valori FileMaker, solo informativi |

### Tabella `valutazioni` (vedi `storico.sql`)

Volutamente **separata da `schede`**: *Aggiorna archivio* fa `delete` su
`schede`, e uno storico lì dentro sparirebbe al primo allineamento.

Oltre ai quattro numeri (`costo_ml`, `costo_mq`, `prezzo_ml`, `prezzo_mq`) e al
`divisore`, la colonna `dettaglio` jsonb congela la composizione di quel giorno:

```json
{ "filati": [ { "ruolo": "ordito", "n": 1, "nome": "...", "cod": "8F202",
                "k": "8F202", "gm": 77.85, "prezzo": 7.0 } ],
  "calo": 3, "ordit": 0.41, "tar": 0.15, "battute": 14,
  "fin": [1.0, 0, 0], "peso_ordito": 239, "peso_trama": 107,
  "altezza_finita": 120.5,
  "voci": { "materie_prime": 2.46, "calo": 0.07, "orditura": 0.10,
            "tessitura": 2.10, "finissaggi": 1.00 } }
```

### Accesso

RLS attiva, policy `to authenticated`, più i **`grant` espliciti** su tabelle e
sequenze: nel progetto Supabase l'opzione *"Automatically expose new tables"* è
spenta, quindi senza quei grant si prende `permission denied` anche da utenti
autenticati. Sono già in fondo a `schema.sql` e `storico.sql`.

La chiave in `config.js` è la **publishable / anon**: è fatta per stare in chiaro,
da sola non legge niente perché le policy pretendono un utente autenticato.
La chiave **`service_role` non deve mai** entrare nel repository, in `config.js`,
in una chat o in qualunque cosa arrivi a un browser.

---

## 4. Il calcolo del costo — la parte di dominio

Questa è la logica che dal codice si ricostruisce male, quindi va letta.

### I pesi dei singoli filati

Una scheda ha **più filati in ordito** (fino a 7-8) e **una o due trame**, non
"un ordito e una trama". I campi `gr1`…`gr10` danno il peso di ciascun filato in
kg/m, ma sono **al netto dell'imborso**: sommati non tornano con `ord`.

Verificato su 4.983 record: la mediana di `ord / (Σgr × (1 + imborso/100))` è
**0,9979**. Quindi il codice **non somma i `gr`**: li usa come **proporzioni** e
li ridistribuisce sul peso ufficiale `ord` (e le trame su `Tra 100`). Così la
somma dei pesi per filato fa sempre esattamente il peso della scheda.
È la funzione `filatiCosto()`.

### La catena del costo

```
materie prime = Σ ( g/m del filato ÷ 1000 × €/kg del filato )
calo          = materie prime × calo%
orditura      = peso ordito ÷ 1000 × €/kg orditura
tessitura     = tariffa battuta × battute
finissaggi    = finissaggio 1 + 2 + 3        (€/m diretti)

costo totale €/m  = somma delle voci qui sopra
costo totale €/m² = €/m ÷ (altezza finita ÷ 100)

prezzo di vendita = costo totale ÷ divisore
```

Il **divisore sostituisce il margine**: non è una percentuale di ricarico, è il
numero per cui si divide (0,86 significa più o meno "+16%"). Default 0,86,
modificabile a mano, e viene congelato nello storico.

Riscontro numerico sull'articolo 8000 · 120 · 861, con 8 / 11 / 6,5 / 9 €/kg:
costo **4,28 €/m**, vendita **4,98 €/m** con divisore 0,86.

### I prezzi dei filati

Sono **per browser**, non sul database: stanno in `localStorage` sotto
`prezzi_filati`, con chiave la **codifica del filato**. Lo stesso filato può
stare in ordito e in trama: ha una codifica sola, quindi un prezzo solo, e
scrivendolo da una parte si allinea l'altra. I valori manuali delle lavorazioni
stanno in `voci_costo`.

Diventano permanenti e condivisi **solo quando salvi una valutazione**.

---

## 5. Le viste

`VISTE[]` elenca i riquadri della dashboard; `visteConsentite()` oggi le
restituisce tutte ed è l'aggancio previsto per i permessi per utente.
`disegna()` sceglie cosa disegnare in base a `MODO` (`'scheda'` o `'costo'`).

- **Scheda tecnica** — la scheda di produzione, stampabile su un A4.
- **Calcolo costo** — materie prime, lavorazioni, totali, storico. Stampabile su
  un A4 (lo storico in stampa non esce).
- **Aggiorna archivio** — legge il foglio `MODELLO` dell'Excel e ricarica tutto.

### Lo storico

Due viste, commutabili, scelta ricordata in `localStorage['storico_vista']`:

- **Confronto** (predefinita): due valutazioni affiancate con in mezzo la
  differenza. `ST_A` e `ST_B` sono gli indici dentro `STORICO`; `ST_APRI` tiene
  aperte o chiuse le righe piegate. **Le voci rimaste uguali si piegano** in una
  riga sola: è il punto della vista, si vede solo ciò che è cambiato. Le colonne
  hanno larghezza fissa, così con due valutazioni non si allarga a vuoto.
- **Elenco**: le valutazioni una sotto l'altra, apribili, con il dettaglio e le
  voci cambiate evidenziate rispetto alla precedente.

Era stata provata prima una **matrice** con una colonna per valutazione: scartata
perché costringeva a leggere colonne quasi identiche e lasciava buchi con poche
valorizzazioni.

### Il telefono (≤760px)

Non è la pagina da scrivania rimpicciolita:

- testata su una riga sola; la lente apre i campi di ricerca con l'elenco dei
  risultati, i tre puntini raccolgono Stampa / Aggiorna archivio / Esci;
- una colonna sola, ogni filato è una scheda con nome e totale sopra, grammi e
  campo €/kg sotto;
- **barra fissa in fondo** con costo e vendita sempre aggiornati mentre scrivi i
  prezzi; toccandola si apre dal basso il pannello con ripartizione, divisore e
  salvataggio;
- lo **storico è una schermata a sé**, si apre dalla riga sotto le lavorazioni.

---

## 6. Trappole — cose su cui si è già sbattuto

- **Il service worker va versionato a ogni rilascio.** `var VERSIONE =
  'schede-vNN'` in `sw.js`: se non lo cambi, Chrome continua a servire la
  versione vecchia dalla cache e sembra che il push non sia andato.
- **Collisioni di nomi di classe.** `index.html` è un file solo e il CSS è
  globale: esiste già `.riga { height: 0 }` come distanziatore, e una tabella che
  usava `.riga` si è ritrovata le righe schiacciate a zero. Le classi nuove vanno
  prefissate (`.cf*` per il confronto, `.tabst`, `.riga-st`…).
- **`.wrap` ha `margin: 0 auto`.** Dentro un contenitore flex in colonna i
  margini automatici **disattivano lo stretch**: senza `width: 100%` esplicito
  prende la larghezza del contenuto e allarga la pagina.
- **Gli SVG scritti a mano**: `<path ... />` non va spezzato fra la barra e il
  maggiore, altrimenti il tag non si chiude e i path si annidano.
- **`Aggiorna archivio` cancella tutta `schede`**: niente dato derivato o
  inserito a mano lì dentro, va in una tabella sua.
- **Il marchio si usa sempre intero**: la guglia con la Madonnina del Duomo fa
  parte del logo, non è un ornamento da ritagliare per fare un'icona.
- **I pesi delle valutazioni vecchie sono quelli di allora**: se l'Excel cambia i
  pesi di un articolo, due valutazioni lontane confrontano tessuti un po'
  diversi. I pesi si vedono nel dettaglio, quindi ce ne si accorge.

---

## 7. Cose previste e non fatte

- **Listino filati** su Supabase, con chiave la codifica, per riempire da solo i
  prezzi €/kg invece di riscriverli ogni volta. È la mancanza più sentita.
- **Permessi per utente**: tabella su Supabase letta da `visteConsentite()`.
  Attenzione: nascondere un riquadro **non protegge i dati**, perché tutte le
  viste leggono la stessa tabella. Dati davvero riservati vogliono una tabella
  separata con le sue policy.
- **Vista "Andamento"** dello storico, disegnata ma non scritta: grafico del
  costo e del prezzo nel tempo, e sotto un diario che per ogni valutazione
  elenca solo le voci cambiate rispetto a quella prima.
- **Valutazioni fra articoli diversi** ("tutte quelle di ottobre").
- Il **logo sull'A4 stampato** e sulla pagina *Aggiorna archivio*.

---

## 8. Come si lavora

Il repository è privato. Si modifica `index.html`, si **alza la versione in
`sw.js`**, si fa push su `main`: Netlify ripubblica da solo in un minuto.
L'Excel non sta nel repository ed è troppo grande per starci.

Prima di considerare finita una modifica alla vista costo, vale la pena
controllare quattro cose, che si sono rotte tutte almeno una volta:
la pagina non deve scorrere in orizzontale, la stampa deve restare su **un solo
foglio A4** (sia scheda sia calcolo costo), il telefono a 390px non deve avere
niente fuori schermo, e lo storico aperto non deve tagliare le righe.
