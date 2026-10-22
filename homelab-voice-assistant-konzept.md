# Konzept: Lokaler Sprachassistent mit Agent-Brain für homedepot

## 1. Die Idee in einem Absatz

Home Assistant übernimmt alles, was mit Mikrofonen, Sprache und Geräten zu tun hat. Ein eigener **Brain-Service** übernimmt das Denken: Tool-Aufrufe, Hintergrund-Jobs, Gedächtnis und die Entscheidung, wann eine Aufgabe zu groß für das lokale Modell ist und an Claude Code übergeben wird. Alle Fähigkeiten (HomeSuite, Musik, Kalender, Gitea, …) werden als **MCP-Server** angebunden. Dadurch nutzen das lokale Modell und Claude exakt dieselben Werkzeuge, und du baust jede Integration nur einmal.

**Zielbild:** Der Assistent soll sich anfühlen wie ein Roboter, mit dem man sich unterhalten kann – mit echten Gesprächen und etwas eigenem Mitdenken. Gespräch, Steuerung und Jobs laufen lokal auf einer **RTX 5060 Ti mit 16 GB**; die schwere Arbeit übernimmt Claude per CLI im Hintergrund.

Die wichtigste Designregel: **Sprache ist nur ein Eingang.** Der Brain bekommt Text – ob der vom Satelliten, von einer Push-Nachricht, einem Cronjob oder einem Gitea-Webhook kommt, ist egal.

---

## 2. Architektur

```
 ┌──────────────── Räume ─────────────────┐
 │  Satellit (Voice PE / Pi + Mikro)      │  Wake Word lokal am Gerät
 └───────────────────┬────────────────────┘
                     │ ESPHome / Wyoming  (IoT-VLAN)
 ┌───────────────────▼────────────────────┐
 │  Home Assistant – Assist Pipeline      │
 │   STT: faster-whisper (Wyoming)        │
 │   TTS: Piper (Wyoming)                 │
 │   Fast Path: lokale Intents            │
 └───────────────────┬────────────────────┘
                     │ Text rein / Text raus
 ┌───────────────────▼────────────────────┐
 │  BRAIN (Orchestrator)                  │
 │   Router → Agent-Loop → Job-Queue      │
 │   Scheduler · Memory · Audit-Log       │
 │   Postgres (+ pgvector)                │
 └──────┬──────────────┬──────────────┬───┘
        │              │              │
 ┌──────▼─────┐ ┌──────▼──────┐ ┌─────▼──────────────┐
 │ Ollama     │ │ MCP-Server  │ │ Claude-Runner      │
 │ lokales    │ │ HomeSuite   │ │ Sandbox-Container  │
 │ LLM        │ │ HA · Musik  │ │ claude -p (headless│
 │            │ │ Kalender    │ │ + gleiche MCPs)    │
 └────────────┘ │ Gitea · ntfy│ └────────────────────┘
                └─────────────┘
```

---

## 3. Wie eine Anfrage durchläuft: drei Stufen

**Stufe 0 – Fast Path (kein LLM, < 1 s)**
„Licht im Wohnzimmer aus“, „Musik lauter“ → Home Assistant erkennt das über lokale Intents und führt es direkt aus. Das LLM wird gar nicht gefragt. Das ist wichtig, weil 80 % aller Sprachbefehle simpel sind und sich sofort anfühlen müssen.

**Stufe 1 – Lokaler Agent (1–5 s)**
„Trag 45 Euro Tanken ins Budget ein und spiel danach was Ruhiges“ → Brain schickt das an das lokale Modell, das ruft `homesuite.add_transaction` und `music.play` auf und antwortet kurz per TTS.

**Stufe 2 – Job (Minuten bis Stunden)**
„Schau dir an, warum die SonarQube-Findings im HomeSuite-Repo gestiegen sind, und mach einen Fix“ → Brain antwortet sofort „Mach ich, ich meld mich“, legt einen Job an, der Claude-Runner arbeitet im Hintergrund, erstellt einen PR in Gitea, und du bekommst eine Durchsage oder Push-Nachricht mit Zusammenfassung.

Faustregel für die Sprachlatenz: Wenn die Antwort nicht innerhalb von ~2 Sekunden anfangen kann, wird es ein Job.

---

## 4. Komponenten im Detail

### 4.1 Satelliten (Mikrofon + Lautsprecher pro Raum)

| Option | Beschreibung | Wann sinnvoll |
|---|---|---|
| Home Assistant Voice Preview Edition | ESP32-Gerät, Wake Word on-device (microWakeWord), Plug & Play mit ESPHome | Empfohlener Einstieg |
| FutureProofHomes Satellite1 | ESP32-Dev-Kit mit besseren Mikrofonen/Lautsprecher, ebenfalls ESPHome | Wenn Audioqualität wichtiger ist |
| DIY: Pi / Mini-PC + Mikro-HAT oder USB-Mikro | Läuft mit „Linux Voice Assistant“ (Nachfolger-Ansatz zu wyoming-satellite) | Wenn du basteln willst oder ein Gerät ohnehin schon im Raum steht |

Hinweis: Die Lautsprecher dieser Geräte sind für Sprache okay, für Musik nicht. Musik sollte über richtige Lautsprecher laufen (siehe Music Assistant), der Satellit spricht nur. Ein eigenes Wake Word lässt sich über microWakeWord bzw. openWakeWord trainieren.

Konkrete Modelle inklusive PoE-Varianten, Displays und Preisen stehen in **Abschnitt 7**.

### 4.2 Voice-Pipeline

**Speech-to-Text:** `faster-whisper` über Wyoming. Für Deutsch sind die kleinen Whisper-Modelle spürbar schwächer – auf einer GPU ist ein großes Modell (z. B. large-v3-turbo) die bessere Wahl. Für feste Kommandos gibt es zusätzlich *Speech-to-Phrase*, das auch auf CPU sehr schnell ist, aber nur bekannte Sätze versteht.

**Text-to-Speech:** Piper mit einer deutschen Stimme (z. B. „thorsten“). Das ursprüngliche Piper-Repository wurde im Oktober 2025 archiviert, funktioniert aber weiterhin als Wyoming-Dienst; vor dem Aufsetzen kurz prüfen, wo die aktuelle Weiterentwicklung liegt und ob es inzwischen eine bessere deutsche Alternative gibt.

**Streaming:** TTS-Antworten möglichst gestreamt ausgeben, damit lange LLM-Antworten nicht erst komplett generiert werden müssen.

### 4.3 Home Assistant

Rolle: **Geräte-Hub und Sprach-Pipeline, nicht das Gehirn.**

- In der Assist-Pipeline die Option aktivieren, Befehle bevorzugt lokal zu verarbeiten → das ist der Fast Path.
- Als Conversation Agent wird der Brain eingetragen. Zwei Wege:
  - (a) Der Brain stellt einen OpenAI-kompatiblen `/v1/chat/completions`-Endpunkt bereit, und HA nutzt eine OpenAI-kompatible Conversation-Integration mit eigener Base-URL.
  - (b) Eine Webhook-basierte Custom-Conversation-Integration, die den Text an die Brain-API schickt.
  - Welche Integration aktuell gut gepflegt ist, vor dem Start prüfen – (a) ist meist die robustere Wahl.
- Umgekehrt stellt HA über seine MCP-Server-Integration Geräte und Szenen als Tools bereit, die der Brain (und Claude) nutzen kann.
- Durchsagen an Satelliten laufen über die Announce-Funktion von HA.

### 4.4 Der Brain (Orchestrator)

Das ist das eigentliche Projekt. Ein eigener Service mit diesen Teilen:

**Router** – entscheidet pro Anfrage: direkt antworten, Tool-Call, lokaler Job oder Claude-Job. Zuerst harte Regeln („frag Claude…“, Code-Änderungen, Recherche), danach klassifiziert das lokale Modell mit strukturierter Ausgabe (JSON-Schema bzw. Grammar in Ollama/llama.cpp). Mit nur einer GPU übernimmt dasselbe Modell Router und Agent.

**Agent-Loop** – ein simpler Tool-Loop reicht völlig: Prompt + Tools → Modell → Tool-Calls ausführen → Ergebnis zurück → bis fertig. Ein schweres Framework ist nicht nötig; ein Limit für die Anzahl der Runden aber schon.

**Leitplanken für das lokale Modell** – damit Steuerung zuverlässig bleibt, auch wenn das Modell mal danebenliegt:

- **Wecker, Timer und Jobs sind normaler Code** im Scheduler. Das Modell übersetzt nur Sprache in einen strukturierten Aufruf; einfache Befehle erledigt ohnehin der Fast Path in HA.
- **Wenige Tools pro Anfrage:** Der Router wählt zuerst eine Tool-Gruppe (Musik, HomeSuite, Wecker …), das Modell sieht dann nur diese paar Tools.
- **Ausgabe erzwingen:** Tool-Calls per Grammar bzw. JSON-Schema einschränken, damit keine kaputten Aufrufe entstehen.
- **Zeiten im Code parsen:** „Halb sieben“ oder „übermorgen“ wertet eine Datums-Library aus, nicht das Modell. Das Ergebnis wird zurückgesagt („Wecker für Samstag, 6:30“).
- **Automatische Eskalation:** Scheitert die Validierung zweimal, wird die Anfrage als Job an Claude übergeben.

**Job-Queue und Scheduler** – in Postgres, das du ohnehin nutzt:

```sql
CREATE TABLE jobs (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  kind            text NOT NULL,        -- voice_followup | scheduled | event | heartbeat | claude
  payload         jsonb NOT NULL,
  status          text NOT NULL DEFAULT 'queued', -- queued|running|waiting_approval|done|failed
  priority        int  NOT NULL DEFAULT 5,
  run_at          timestamptz NOT NULL DEFAULT now(),
  attempts        int  NOT NULL DEFAULT 0,
  origin          text,                 -- z.B. 'voice:wohnzimmer', 'cron:morning', 'gitea:webhook'
  result          jsonb,
  cost_usd        numeric,
  created_at      timestamptz NOT NULL DEFAULT now()
);
```

Worker holen Jobs mit `SELECT … FOR UPDATE SKIP LOCKED` – das ist eine vollwertige Queue ohne zusätzliche Infrastruktur.

Job-Arten:

| Art | Beispiele |
|---|---|
| Voice-Follow-up | „Recherchier mal…“, „Erinner mich, wenn…“ |
| Geplant (Cron) | Morgen-Briefing (Kalender, offene HomeSuite-Todos, Budget-Stand), wöchentlicher Security-Report aus Dependency-Track und SonarQube |
| Event-getrieben | HA-Events (Waschmaschine fertig), Gitea-Webhooks (Pipeline rot) |
| Heartbeat („Denkschleife“) | Alle X Minuten prüfen regelbasierte Trigger im Code die Lage: neue Events, offene Jobs, nächste Termine. Nur wenn ein Trigger anschlägt, bekommt das lokale Modell eine kompakte Zusammenfassung und formuliert eine Notiz, einen Vorschlag oder legt einen Job an |

Für den Heartbeat gilt: nur Lese-Tools und Vorschläge, keine Aktionen ohne Bestätigung, nachts keine Durchsagen. Sonst wird die „immer mitdenkende KI“ schnell zur nervigen KI.

**Memory** – Postgres + pgvector: kurzer Gesprächsverlauf pro Raum/Session, langfristige Fakten und Vorlieben, Ergebnisse vergangener Jobs. Per Retrieval nur die relevanten Top-k-Einträge in den Prompt.

**Benachrichtigungen** – TTS-Durchsage im passenden Raum, Push über ntfy (self-hosted, mit Action-Buttons für Bestätigungen), optional ein Eingang in HomeSuite.

**Audit-Log** – jeder Tool-Call mit Argumenten, Ergebnis, Herkunft und Kosten. Hilft beim Debuggen enorm und ist aus Security-Sicht Pflicht.

**Sprache/Stack:** Python (FastAPI + offizielles MCP-SDK) hat das breiteste Ökosystem für diesen Teil. Wenn du lieber in deiner .NET-Welt bleibst, gibt es auch ein C#-MCP-SDK – das würde ich eher für den HomeSuite-MCP-Server nutzen.

### 4.5 Lokales LLM und Gesprächsgefühl

**Entscheidung: NVIDIA RTX 5060 Ti mit 16 GB** in homedepot. Wichtig: nicht die 8-GB-Variante der 5060 Ti und nicht die normale RTX 5060 (ebenfalls nur 8 GB). Preis Stand September 2026: ab ca. 630 €, meist um 700 €.

**Warum nicht kleiner:** Ein Jetson Orin Nano Super wurde geprüft und verworfen. CPU und GPU teilen sich dort 8 GB, und die Speicherbandbreite liegt bei 102 GB/s. Für reine Steuerung mit einem 3–4B-Modell würde das reichen, für echte Gespräche mit Mitdenken plus Whisper gleichzeitig nicht. Die 5060 Ti hat 16 GB mit 448 GB/s – die Bandbreite bestimmt, wie schnell die Tokens kommen.

**Runtime:** Ollama (NixOS-Modul, CUDA), alternativ llama.cpp-Server, wenn mehr Kontrolle nötig ist.

**Modelle, die in 16 GB passen** (Stand September 2026 – vor dem Start aktuelle Tool-Calling-Tests prüfen):

| Modell | Speicher (Q4) | Einsatz |
|---|---|---|
| **Qwen 3.5 9B** | ca. 6 GB | **Startmodell.** Gutes Tool-Calling, lässt Platz für Whisper und einen langen Gesprächsverlauf |
| GPT-OSS 20B | 16 GB oder mehr | Denkt spürbar mehr, belegt aber die ganze Karte → Whisper müsste auf CPU oder einen anderen Host |
| Qwen 3.6-35B-A3B | ca. 24 GB; auf 16 GB nur mit Auslagerung der MoE-Schichten auf die CPU | Experiment für später: braucht viel System-RAM und ist langsamer |

Ein Modell bleibt dauerhaft geladen (`keep_alive`) und übernimmt Router und Agent – kein Nachladen im Sprachpfad. Den VRAM-Verbrauch von Modell, KV-Cache und Whisper im Betrieb mit `nvidia-smi` nachmessen.

**Gesprächsgefühl („Roboter zum Reden“):**

- **Latenz vor Modellgröße:** Die Antwort wird satzweise ans TTS gestreamt, damit der erste Satz nach 1–2 Sekunden kommt und nicht erst, wenn die ganze Antwort fertig ist.
- **Folgefragen ohne Wake Word:** Nach einer Antwort kurz weiter zuhören (Continued Conversation). Einige ESPHome-Firmwares können das bereits.
- **Thinking-Modus im Gespräch aus:** Sonst entstehen Denkpausen. Längeres Nachdenken ist Sache von Jobs – lokal oder bei Claude.
- **Mitdenken durch Kontext:** Der Brain gibt pro Anfrage eine kurze Lage mit: Uhrzeit, Raum, wer zuhause ist, nächste Termine, offene Jobs und relevante Memory-Einträge. Kompakt halten: Schon 30 freigegebene HA-Entitäten kosten rund 1.300 Tokens, also nur exponieren, was gebraucht wird.
- **Charakter per System-Prompt:** Name, Tonfall, kurze Sprachantworten (1–3 Sätze), Rückfragen ausdrücklich erlaubt.
- **Proaktiv, aber gebremst:** Vorschläge statt Aktionen, z. B. „Du hast in einer Stunde einen Termin – soll ich die Musik dann leiser machen?“

**Einbau in homedepot:** freier PCIe-x16-Slot, ausreichend Netzteil-Reserve, nach dem Einbau den Idle-Verbrauch messen (läuft 24/7). NixOS-Details siehe Abschnitt 6.

### 4.6 Tools als MCP-Server

| MCP-Server | Fähigkeiten | Umsetzung |
|---|---|---|
| HomeSuite | Transaktionen eintragen, Todos, Kategorien, Budget-Abfragen | Eigener MCP-Server im ASP.NET-Backend oder als Adapter vor deiner API, mit eigenem Service-Account und eingeschränkten Scopes |
| Home Assistant | Geräte, Szenen, Zustände | Integrierte MCP-Server-Integration von HA |
| Musik | Abspielen, Playlists, Räume, Lautstärke | Music Assistant (Spotify, lokale Bibliothek, Multiroom über Snapcast/Chromecast/AirPlay/DLNA) |
| Kalender | Termine lesen/anlegen | CalDAV (z. B. Radicale) |
| Gitea | Issues, PRs, Pipeline-Status | Gitea-MCP-Server bzw. kleiner Adapter über die API |
| Audiobookshelf | „Hörbuch weiterspielen“ | Kleiner Adapter über die API |
| Notify | Durchsagen, Push mit Bestätigung | HA-Announce + ntfy |
| Web | Recherche | SearXNG self-hosted (Achtung: Prompt-Injection-Quelle, siehe Security) |

Designregeln für Tools:

- **Schmale, explizite Tools** statt generischer API-Wrapper: `add_transaction(amount, category, note, date)` statt `call_homesuite_api(method, path, body)`. Lokale Modelle werden damit massiv zuverlässiger.
- Tools als lesend bzw. destruktiv kennzeichnen (MCP bietet dafür Annotations), damit der Brain Bestätigungen automatisch erzwingen kann.
- Gute Beschreibungen und Beispiele in den Tool-Definitionen – das ist bei kleinen Modellen die halbe Miete.

### 4.7 Claude-Runner (Eskalation)

**Warum die CLI:** Claude Code bringt Agent-Loop, Datei-Tools und MCP-Client schon mit. Du gibst nur Aufgabe, Arbeitsverzeichnis und Berechtigungen vor.

**Ablauf:**
1. Brain legt Job `kind=claude` an (optional erst nach Bestätigung).
2. Runner-Container bereitet einen frischen Workspace vor (Clone oder git worktree, eigener Branch).
3. Aufruf im Headless-Modus, Ergebnis als JSON.
4. Brain speichert Ergebnis, Kosten und Session-ID, erzeugt Benachrichtigung.
5. Code-Änderungen landen als PR in Gitea – und laufen damit durch deine bestehende Pipeline mit SonarQube und Dependency-Track wie jeder andere Code.

**Beispielaufruf** (Flags vor dem Umsetzen gegen die aktuelle Doku prüfen):

```bash
claude -p "$TASK" \
  --output-format json \
  --json-schema "$(cat /etc/brain/claude-result.schema.json)" \
  --mcp-config /etc/brain/mcp-claude.json \
  --allowedTools "Read,Grep,Glob,Edit,Bash(git diff *),Bash(git commit *),Bash(dotnet test *)" \
  --max-turns 30 \
  --append-system-prompt "Du arbeitest als Hintergrund-Job im Homelab. Arbeite nur auf dem vorbereiteten Branch und pushe nie nach main."
```

Das Result-Schema könnte so aussehen:

```json
{
  "type": "object",
  "properties": {
    "voice_summary": { "type": "string", "description": "1-2 Sätze für die Durchsage" },
    "details":       { "type": "string" },
    "pr_url":        { "type": "string" },
    "needs_followup":{ "type": "boolean" }
  },
  "required": ["voice_summary", "details", "needs_followup"]
}
```

**Nützliche Punkte aus der Headless-Doku:**
- Die JSON-Ausgabe enthält Ergebnis, Session-ID und Metadaten inklusive geschätzter Kosten → pro Job loggen und im Brain ein Tages-/Monatsbudget erzwingen.
- Mit der Session-ID lassen sich Folgeaufträge im selben Kontext fortsetzen („mach noch Tests dazu“).
- Für unbeaufsichtigte Läufe gibt es eine Option, die Tools entfernt, die eine menschliche Antwort bräuchten – sonst hängt der Job.
- Für mehr Kontrolle (Tool-Approval-Callbacks, native Message-Objekte) kann der Runner später vom CLI auf das Agent SDK (Python/TypeScript) umgestellt werden.

**Authentifizierung:** Für einen unbeaufsichtigten Server-Dienst ist ein API-Key (als Secret, nicht im Image) der sauberste Weg; die Kosten laufen dann über die API-Abrechnung.

**Wann eskalieren:**
- Code-Änderungen, Refactorings, Bugfixes
- Mehrstufige Recherche oder lange Dokumente
- Der lokale Agent scheitert zweimal an derselben Aufgabe
- Du sagst es explizit („frag Claude“)
- **Nicht** für Smart-Home-Befehle oder simple Einträge

---

## 5. Security

Das ist der Teil, bei dem man sich bei Agent-Systemen am leichtesten ins Knie schießt.

**Stimme ist keine Authentifizierung.** Fernseher, Gäste und YouTube-Videos können sprechen. Deshalb drei Stufen:

| Stufe | Beispiele | Regel |
|---|---|---|
| Lesen | Status, Termine, Budget-Stand | Sofort |
| Harmloses Schreiben | Musik, Licht, Budget-Eintrag | Sofort, aber geloggt |
| Sensibel | Löschen, Türschloss, Claude-Jobs mit Code-Änderungen, alles was Geld kostet | Bestätigung per ntfy-Action oder PIN |

**Prompt Injection:** Webseiten, E-Mails, Issue-Texte und Job-Ergebnisse sind nicht vertrauenswürdig. Ein Agent-Durchlauf, der solchen Content gelesen hat, bekommt keine schreibenden Tools mehr ohne Bestätigung.

**Claude-Runner isolieren:** eigener Container, kein Docker-Socket, keine Secrets im Workspace, eng gescopte `--allowedTools`, Netzwerk-Egress nur zu Anthropic-API, Gitea und Paket-Registries. Änderungen nur per PR, nie direkter Push.

**Least Privilege pro MCP-Server:** eigene Tokens, HomeSuite-Service-Account nur mit den nötigen Rechten.

**Netzwerk:** Satelliten ins IoT-VLAN, dürfen nur mit HA reden. Brain, Ollama und Whisper nicht nach außen exponieren. Intern TLS über deine bestehende CA und nginx.

**Secrets:** sops-nix oder agenix.

**Audio:** Aufnahmen standardmäßig nicht speichern.

---

## 6. Deployment auf NixOS

Vieles gibt es direkt als NixOS-Modul:

```nix
{ pkgs, ... }:
{
  # RTX 5060 Ti (Blackwell): nur mit den offenen NVIDIA-Kernelmodulen
  nixpkgs.config.allowUnfree = true;
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];   # lädt den Treiber auch headless
  hardware.nvidia.open = true;

  services.home-assistant.enable = true;          # oder als OCI-Container, falls du HACS brauchst
  services.wyoming.faster-whisper.servers.de = { enable = true; language = "de"; /* model, device = "cuda" */ };
  services.wyoming.piper.servers.de = { enable = true; /* voice */ };
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;                   # ältere nixpkgs: acceleration = "cuda";
  };
  services.music-assistant.enable = true;
  services.postgresql.extensions = ps: [ ps.pgvector ];
}
```

(Optionsnamen gegen die aktuelle nixpkgs-Version prüfen – gerade bei Ollama und dem NVIDIA-Treiber ändern sie sich gelegentlich.)

Brain und Claude-Runner als eigene Images, gebaut über Gitea Actions, deployt über `virtualisation.oci-containers` – passt zu deinem bestehenden Setup und läuft automatisch durch die Security-Pipeline.

---

## 7. Hardware-Liste mit Preisen

Preise Stand September 2026. Sie schwanken derzeit stark, weil die Speicherkrise Raspberry Pis und GPUs verteuert hat. USD-Preise sind Shop-Preise aus den USA – dazu kommen Versand und 20 % Einfuhrumsatzsteuer. PoE wird bevorzugt, WLAN ist aber okay.

### 7.1 Sprach-Satelliten (Mikrofon + Lautsprecher)

| Modell | Anschluss | Preis | Anmerkung |
|---|---|---|---|
| **Home Assistant Voice Preview Edition** | WLAN, Strom per USB-C (5 V / 2 A) | ab ca. 64 € | Empfohlener Start. Mit PoE-auf-USB-C-Splitter (ca. 15–20 €) kommt der Strom übers Netzwerkkabel, Daten laufen weiter per WLAN |
| FutureProofHomes Satellite1.1 Smart Speaker | WLAN | ab ca. 131 USD (DIY-Dev-Kit ca. 70 USD) | Deutlich besserer Lautsprecher, braucht aber ein 30-W-USB-C-PD-Netzteil → für PoE ungeeignet; PoE-Version noch nicht erhältlich |
| reSpeaker XVF3800 + XIAO ESP32S3 | WLAN oder als USB-Mikro | ca. 65–67 USD | Beste Mikrofone der Liste (4 Stück, bis ca. 5 m). ESPHome-Support als Community-Projekt noch in Entwicklung; Lautsprecher separat |
| Raspberry Pi 5 + PoE+ HAT + XVF3800 per USB | PoE | Pi 5 (4 GB) ab ca. 100 €, PoE+ HAT ca. 20–25 USD, plus Mikro | Echtes PoE mit Linux Voice Assistant, durch die Pi-Preiserhöhungen aber teuer |
| Waveshare ESP32-P4-WIFI6-POE-ETH | PoE | ca. 22–70 € je nach Paket | Echtes PoE, Mikro und Lautsprecher selbst anschließen. ESPHome-Voice auf dem P4 läuft in Community-Projekten – Bastellösung |

### 7.2 Displays

| Modell | Anschluss | Preis | Anmerkung |
|---|---|---|---|
| Waveshare ESP32-P4-86-Panel-ETH-2RO | Ethernet | ca. 50 USD | 4" mit 720×720 für die Unterputzdose. Fertige ESPHome-Firmware mit Sprachassistent, Timern und Mediensteuerung; Stromversorgung vor Kauf im Datenblatt prüfen |
| Waveshare ESP32-P4-WIFI6-Touch-LCD 7 / 8 / 10,1" | WLAN | ca. 70–78 € | Mit zwei Mikros und Lautsprecher – Display und Satellit in einem; ESPHome-Support weniger erprobt |
| **10" PoE-Android-Wandtablet** (RK3566/RK3568, China) | PoE (802.3af) | ab ca. 144 € + Versand, bis ca. 270 € | Mit **Kiosk Satellite** (freie Kiosk-App für HA mit nativer Wake-Word-Erkennung, auch bei ausgeschaltetem Bildschirm) gleichzeitig Dashboard und Satellit. Guter Ort für Job-Status und Claude-Ergebnisse |
| Lenovo ThinkSmart View (gebraucht) | WLAN | um 40 USD laut View-Assist-Projekt | Budget-Option mit gutem Lautsprecher, von View Assist unterstützt |

### 7.3 Musik (für Music Assistant)

| Modell | Preis | Anmerkung |
|---|---|---|
| WiiM Pro Plus | ca. 200 € | Streamer für eine vorhandene Anlage, AirPlay 2 / Chromecast / DLNA |
| WiiM Amp | 299 USD (US-Preis) | Streaming-Verstärker, Lautsprecher direkt anschließen, auch per Ethernet |
| Sonocotta Louder ESP32 | ca. 24 USD | Stereo bis 23 W pro Kanal; die Plus-Variante läuft laut Käufern per ESPHome/Sendspin sauber mit HA und Music Assistant |
| Esparagus Audio Brick | 59 USD | 65 W, Hutschiene, optional Ethernet, unterstützt Music Assistant und Snapcast |

Verstärker brauchen meist mehr Leistung, als PoE sinnvoll liefert – hier ein Netzteil einplanen.

### 7.4 KI-Hardware

| Modell | Preis | Status |
|---|---|---|
| **RTX 5060 Ti 16 GB** | ab ca. 630 €, meist um 700 € | **Gewählt** – siehe Abschnitt 4.5 |
| RTX 3090 24 GB (gebraucht) | ca. 800–1.150 USD (Juni 2026) | Alternative mit mehr VRAM, aber deutlich höherem Verbrauch |
| Jetson Orin Nano Super 8 GB | 399 USD bei NVIDIA, Bundles um 450 USD | Verworfen – reicht nur für reine Steuerung mit 3–4B-Modell |
| Mini-PC mit Ryzen AI Max+ 395 (128 GB) | Start um 2.000 USD, bei EU-Händlern teils fast 4.900 € | Verworfen – nur für sehr große Modelle sinnvoll |

### 7.5 Sonstiges

| Was | Anmerkung |
|---|---|
| Anthropic-API-Key | Nutzungsbasiert, Budget-Limit im Brain erzwingen |
| PoE-Switch | Falls noch keiner vorhanden ist |
| Software | Alles Open Source bzw. self-hosted |

### 7.6 Starter-Set

1× Voice PE mit PoE-Splitter, 1× PoE-Android-Panel mit Kiosk Satellite, 1× Louder ESP32 oder WiiM Pro Plus: grob **250–530 €**, dazu die RTX 5060 Ti mit ca. **630–700 €**.

---

## 8. Roadmap

Jede Phase liefert etwas Nutzbares.

**Phase 1 – Stimme & Geräte:** HA, faster-whisper, Piper, ein Satellit, Fast Path, Music Assistant. Ergebnis: funktionierende lokale „Alexa“ für Licht und Musik.

**Phase 2 – Brain & lokales LLM:** RTX 5060 Ti einbauen, Ollama mit Qwen 3.5 9B, Brain mit Router, Tool-Loop und Leitplanken, erste MCP-Server (HomeSuite, Music Assistant, HA), Antworten satzweise gestreamt. Ergebnis: „Trag ein…“, freie Sätze und erste echte Gespräche funktionieren.

**Phase 3 – Jobs & Benachrichtigungen:** Job-Queue, Scheduler, ntfy, Morgen-Briefing, Event-Trigger. Ergebnis: der Assistent arbeitet auch, wenn du nicht redest.

**Phase 4 – Claude-Runner:** Sandbox-Container, PR-Workflow, Kosten-Tracking, Bestätigungen. Ergebnis: komplexe Aufgaben per Sprache delegieren.

**Phase 5 – Feinschliff:** Heartbeat-Denkschleife, Memory, Multiroom, eigenes Wake Word, Präsenzerkennung für raumbezogene Antworten.

---

## 9. Offene Entscheidungen

- Hat homedepot einen freien PCIe-x16-Slot und genug Netzteil-Reserve für die RTX 5060 Ti – oder braucht es doch einen separaten AI-Node?
- Startmodell im Alltag testen: Qwen 3.5 9B gegen GPT-OSS 20B (Gesprächsqualität vs. Platz für Whisper)?
- Welche Räume bekommen einen Satelliten, wo lohnt sich ein Display?
- Brain in Python oder .NET?
- Musikquelle: Spotify, lokale Bibliothek oder beides?
- Welche Aktionen genau brauchen eine Bestätigung?
- Wie „proaktiv“ darf der Heartbeat sein, bevor er nervt?
