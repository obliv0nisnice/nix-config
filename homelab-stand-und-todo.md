# Stand & TODO – nix-config + Sprachassistent

Stand: 2026-10-19. **Nichts davon ist committet oder per Rebuild aktiviert.**
Alles liegt als Arbeitskopie im Repo (`git status`). Neue Dateien sind mit
`git add` eingetragen, damit der Flake sie sieht.

Zum Weitermachen in einer neuen Claude-Sitzung:
> „Lies `homelab-stand-und-todo.md` und `homelab-voice-assistant-konzept.md`, wir machen bei *Als Nächstes* weiter.“

---

## 1. Erledigt – Aufräumen der Config

| Was | Wo |
|---|---|
| Netbird verbindet sich am Mac nicht mehr automatisch (`netbird-wt0 up` / `down`) | `hosts/macbook/variables.nix` → `network.netbird.autoConnect = false` |
| Ein Netbird-Modul für Server + Mac statt zwei | `modules/core/netbird.nix` (alt: `modules/server/netbird.nix`, `modules/apple-silicon/netbird.nix`) |
| Alle Schalter in einem Baum, `customConf` gibt es nicht mehr | `modules/core/profiles.nix` |
| Neue Schalter: `desktop.lockscreen`, `desktop.fingerprint`, `network.netbird`, `network.nasMount`, `dev.mobile`, `dev.gamedev` | jede `hosts/*/variables.nix` listet weiterhin **alle** Schalter |
| Server bekommt keine Desktop-Apps mehr (Android Studio, Godot, Blender, evil-winrm, remmina …) | `modules/core/packages.nix` |
| `variables.nix` wird einmal im Flake geladen und als `vars` übergeben (statt 8× `import`) | `flake.nix` |
| Gelöscht: `hosts/nixos`, `hosts/default/{default,variables,host-packages}.nix`, `nixvim/clipboard.nix`, `core/starfish.nix`, ZaneyOS-Variablen | – (`hosts/default/hardware.nix` bleibt, wird von 4 Hosts genutzt) |
| Alias `os-rebuild` zeigt auf `~/nix-config#<host>` statt auf das nicht vorhandene `~/NixOS#macbook` | `modules/home/zsh.nix` |
| Gitea: entferntes `DOMAIN` raus (`ROOT_URL` war schon gesetzt) → `homedepot` evaluiert wieder | `modules/server/git/gitea.nix` |

**Nebeneffekt:** Die x86-Desktops haben jetzt `security.pentest` und `remoteScan` an, damit evil-winrm und remmina bleiben. Dadurch kommen impacket, medusa, smtp-user-enum, openconnect und openscap neu dazu. Wenn du das nicht willst, die beiden Schalter ausmachen.

## 2. Erledigt – Server-Vorbereitung Sprachassistent

Alles unter `modules/server/assistant/`, Schalter `server.assistant.*` in `hosts/homedepot/variables.nix`, **alle aktuell `false`**.

| Schalter | Inhalt |
|---|---|
| `gpu` | RTX 5060 Ti: NVIDIA `stable` + `open = true`. Solange **aus**: `legacy_580` für die alte Karte (vor Turing, ab Serie 590 nicht mehr unterstützt) |
| `homeAssistant` | natives HA mit esphome, wyoming, music_assistant, mcp_server; Port 8123 im LAN offen; vHost `ha.nestlerlabs.at` |
| `voice` | faster-whisper (de) + Piper `de_DE-thorsten-high`, nur localhost (:10300 / :10200). Ohne GPU auf CPU, mit `gpu` CUDA + `large-v3-turbo` |
| `ollama` | `ollama-cuda`, nur localhost, `qwen3.5:9b`, `OLLAMA_KEEP_ALIVE=-1`. Ohne `gpu` bricht der Build bewusst ab |
| `musicAssistant` | Provider: hass, hass_players, airplay, chromecast, dlna, wiim |
| `ntfy` | `ntfy.nestlerlabs.at`, nur mit Login (`deny-all`) |
| `brainDb` | DB + User `brain` im bestehenden Postgres, pgvector aktiviert |

Treiber-Default in `modules/drivers/nvidia-drivers.nix` ist jetzt `mkDefault` (für die anderen Hosts ohne Änderung).

**Geprüft (nur ausgewertet, nichts gebaut):**
- Alle Schalter aus: alle 7 Hosts ergeben exakt dieselben Derivations wie vorher.
- Alles an bzw. Phase 1 ohne GPU: `homedepot` lässt sich auswerten.
- Whisper mit GPU hängt an einem CUDA-gebauten `ctranslate2`.
- `homedepot`: `gpu = false` → Treiber 580.178, `open = false`; `gpu = true` → 595.104, `open = true`.

Hinweis für Prüfungen: Nix-Auswertungen **nacheinander** laufen lassen. 21 parallele Evals haben die letzte Sitzung zum Absturz gebracht (Speicher).

---

## 3. Als Nächstes

### Jetzt
- [ ] Diff durchsehen (`git diff`, `git status`) und committen.
- [ ] Mac rebuilden (`os-rebuild`), Netbird testen: `netbird-wt0 up` / `down`.
- [ ] `homedepot` rebuilden. Prüfen, ob die alte Karte mit `legacy_580` läuft (`nvidia-smi`).

### Phase 1 – ohne neue Hardware möglich
- [ ] DNS + Zertifikat für `ha.` und `ntfy.nestlerlabs.at` (AdGuard-Rewrite, step-ca), falls kein Wildcard.
- [ ] `homeAssistant`, `voice`, `musicAssistant`, `ntfy` auf `true` → Rebuild.
- [ ] HA im Browser einrichten (Benutzer, Standort, Sprache Deutsch).
- [ ] In HA: Integration *Wyoming* zweimal hinzufügen (`127.0.0.1:10300` Whisper, `127.0.0.1:10200` Piper), Assist-Pipeline auf Deutsch mit beiden anlegen, „Befehle bevorzugt lokal verarbeiten“ aktivieren.
- [ ] ntfy-Benutzer: `sudo ntfy user add --role=admin <name>`.
- [ ] Ersten Satelliten kaufen (Voice PE) und einbinden (siehe Abschnitt 5).
- [ ] mDNS für die automatische Erkennung von ESPHome-Geräten: Auf `homedepot` ist `networkDiscovery` aus und UDP 5353 zu. Entweder freigeben oder Satelliten in HA per IP hinzufügen.

### Phase 2 – wenn die RTX 5060 Ti da ist
- [ ] Netzteil-Reserve und freien PCIe-x16-Slot prüfen, Karte einbauen.
- [ ] Tag `qwen3.5:9b` auf ollama.com prüfen und in `assistant/ollama.nix` ggf. anpassen.
- [ ] `gpu`, `voice`, `ollama` auf `true` → Rebuild. **Dauert lange:** das CUDA-`ctranslate2` wird lokal gebaut.
- [ ] `nvidia-smi`: VRAM-Verbrauch (Modell + KV-Cache + Whisper) und Idle-Verbrauch messen.
- [ ] `brainDb` an; Passwort + TCP-Zugang über sops ergänzen, sobald der Brain-Container existiert.

### Phase 3+ – noch nicht vorbereitet
- [ ] Brain (Router, Tool-Loop, Job-Queue) als Image über Gitea Actions → `virtualisation.oci-containers`.
- [ ] Claude-Runner-Container (Sandbox, PR-Workflow, Kostenlimit, API-Key über sops).
- [ ] MCP-Server: HomeSuite, Music Assistant, Gitea, Audiobookshelf.
- [ ] SearXNG, Radicale (Optionen gibt es in nixpkgs).
- [ ] Offene Entscheidungen aus dem Konzept, Abschnitt 9.

---

## 4. Bewusst offen gelassen

- **~229 MB Ballast** in `modules/server/Backend` + `modules/server/Caddy` (2135 .NET-Build-Dateien in bin/obj/out, `result`-Symlink, `access.log`). Wird bei jedem Rebuild mit in den Store kopiert, kein aktives Modul nutzt ihn. → auslagern bzw. aus Git entfernen + `.gitignore`.
- **Tote Server-Dateien:** `auto-upgrade.nix`, `caddy.nix`, `mail.nix`, `minecraft-server.nix`, `installPhase.nix`, `HomeDepotBackend.nix`, `Backend.nix`, `Caddy/test.nix`, `certs/certs.nix`.
- **Hardcodierte `/home/jakob/...`-Pfade** in nginx, jellyfin, audiobookshelf, caddy.
- **Profile auf `_common.nix` vereinheitlichen** (amd/intel/vm/nvidia-laptop): würde dort das GRUB-Theme ändern (Minegrub-Modul).
- **Mac evaluiert ohne `--impure` nicht** (Asahi-Firmware-Pfad). Passt wahrscheinlich zu `modules/apple-silicon/firmware.nix`, die nicht eingebunden ist.
- Leere `hosts/*/host-packages.nix` behalten (Platz für Pakete, die nur ein einzelner Host braucht).

---

## 5. Was mit „Satelliten“ gemeint ist

Ein **Satellit** ist ein kleines Gerät pro Raum mit **Mikrofon und Lautsprecher**, ungefähr wie ein Echo Dot, nur ohne Cloud. Er denkt selbst nicht. Die ganze Intelligenz sitzt zentral auf `homedepot`, die Satelliten „kreisen“ darum, daher der Name.

**Was im Satelliten passiert:** nur das Wake Word („Okay Nabu“ o. ä.), lokal auf dem Chip. Erst danach wird Audio verschickt. Vorher verlässt nichts das Gerät.

**Ablauf einer Anfrage:**
1. Du sagst das Wake Word, der Satellit hört es selbst.
2. Er streamt deine Sprache per WLAN an Home Assistant auf `homedepot`.
3. HA → **faster-whisper** macht Text daraus.
4. Text → Fast Path in HA (Licht, Musik) oder später an den Brain / Ollama.
5. Antworttext → **Piper** macht daraus eine Audiodatei.
6. Der Satellit holt sich diese Datei von HA (darum ist Port 8123 im LAN offen) und spielt sie ab.

**Einbinden:** Satelliten wie die Voice PE laufen mit ESPHome. HA verbindet sich zum Gerät (Port 6053 am Gerät), das Gerät holt TTS-Audio von HA (:8123). Mehr Verbindungen braucht es nicht, darum passt das gut in ein abgeschottetes IoT-VLAN, das nur mit HA reden darf.

**Musik:** Die Satelliten-Lautsprecher sind nur für Sprache gut. Musik läuft über Music Assistant auf richtige Lautsprecher (WiiM, Louder ESP32 …).

**Einstieg:** eine Home Assistant Voice Preview Edition (~64 €), optional mit PoE-auf-USB-C-Splitter. Weitere Modelle: Konzept, Abschnitt 7.1.
