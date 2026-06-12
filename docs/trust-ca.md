# Client-Trust für `*.nestlerlabs.at`

Alle internen Services laufen hinter nginx mit Certs, die unsere private CA (`step-ca`) auf homedepot ausstellt. Damit Browser und Apps grünes Schloss zeigen, muss jedes Gerät den **Root-CA-Cert** einmalig importieren und als trusted markieren.

## Cert holen

```
https://ca.nestlerlabs.at/root_ca.crt
```

Beim allerersten Zugriff warnt der Browser, weil er das Cert ja noch nicht kennt — Warning einmal akzeptieren oder per Terminal:

```bash
curl -kO https://ca.nestlerlabs.at/root_ca.crt
```

## iPhone / iPad

Drei Stufen — die letzte ist die, die man typischerweise vergisst.

1. **Profil herunterladen**
   - In **Safari** (nicht Chrome / Floorp — geht dort nicht) `https://ca.nestlerlabs.at/root_ca.crt` öffnen
   - Dialog "Profil heruntergeladen" mit **Erlauben** bestätigen
2. **Profil installieren**
   - Einstellungen → Allgemein → **VPN und Geräteverwaltung**
   - Unter "Geladenes Profil" das Nestler-Labs-Profil antippen → **Installieren** (oben rechts) → Geräte-PIN → noch zwei mal **Installieren** → **Fertig**
3. **Voll-Trust aktivieren** ← **ohne diesen Schritt bleibt das Cert wirkungslos**
   - Einstellungen → Allgemein → **Info** → ganz unten **Zertifikatsvertrauensseinstellungen**
   - Den Schalter für **Nestler Labs CA Root** aktivieren
   - Warndialog mit **Fortfahren** bestätigen

Test: `https://gitea.nestlerlabs.at` in Safari öffnen → kein Warning, Schloss-Icon grün.

## Floorp / Firefox (Desktop)

Floorp nutzt einen eigenen Cert-Store, nicht den vom System.

1. `about:preferences#privacy`
2. Ganz nach unten → **Zertifikate** → **Zertifikate anzeigen**
3. Tab **Zertifizierungsstellen** → **Importieren…**
4. `root_ca.crt` wählen
5. Häkchen bei **Dieser Zertifizierungsstelle vertrauen, um Websites zu identifizieren** → OK

## Chromium-basierte Browser (Chrome, Brave, Edge, Vivaldi)

Nutzen den System-Trust-Store:

- **Linux**: `~/.pki/nssdb` per `certutil` oder system-weit `/etc/ssl/certs/`. Auf NixOS-Desktops übernimmt `security.pki.certificateFiles` das automatisch — siehe `modules/server/certs.nix` als Referenz, das gleiche Snippet lässt sich in Desktop-Profile (`profiles/nvidia` etc.) ziehen.
- **macOS**: `root_ca.crt` doppelklicken → Schlüsselbund öffnet sich → System → beim Cert "Bei diesem Zertifikat immer vertrauen" einstellen
- **Windows**: `.crt` doppelklicken → **Zertifikat installieren** → **Lokaler Computer** → **Vertrauenswürdige Stammzertifizierungsstellen**

## NixOS-Desktop trusten (nvidia, nvidia-laptop, …)

Wenn du das Cert auch auf einem deiner Desktops als System-Trust haben willst (z.B. damit `curl https://gitea.nestlerlabs.at` ohne `-k` funktioniert), das Cert ins Repo kopieren und in einem Modul einbinden:

```nix
security.pki.certificateFiles = [
  ./certs/step-ca-root.crt
];
```

Vorbild ist `modules/server/certs.nix` auf homedepot.

## Refresher: Wo kommt das Cert her?

Generiert wurde es per `step ca init` auf homedepot, liegt unter `/var/lib/private/step-ca/certs/root_ca.crt` und ist im Repo kopiert nach `modules/server/certs/step-ca-root.crt`. Der nginx-vhost `ca.nestlerlabs.at` (siehe `modules/server/nginx.nix`) liefert es per HTTPS aus.
