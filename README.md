# NixOS

Meine NixOS-Konfiguration für mehrere Maschinen — Desktop mit Hyprland, Laptop, ein paar VMs und ein selbst gehosteter Server.

Alles in einer Flake, geteilte Module, pro Host nur die Schalter umlegen.

## Hosts

| Host | Was es ist |
|---|---|
| `nvidia` | Haupt-Desktop, Hyprland, GPU für Spiele / KI |
| `homedepot` | Server zu Hause — Gitea, SonarQube, Dependency Track, Jellyfin, AdGuard, step-ca |
| `nvidia-laptop` | Laptop mit Nvidia |
| `amd` / `intel` / `vm` | weitere Maschinen / Testumgebungen |

## Struktur

```
flake.nix              Inputs + Host-Definitionen
profiles/_common.nix   Gemeinsame Imports für alle Profile
profiles/<name>/       Spezifische Driver-/Modul-Wahl pro Profil
hosts/<host>/          Hardware-File, Variablen, machineProfiles-Schalter
modules/core/          System-Basis (Boot, Netzwerk, Pakete, Services, Stylix)
modules/home/          Home-Manager (Hyprland, Waybar, nvim, Rofi, Skripte)
modules/server/        Server-Dienste (nginx, AdGuard, Gitea, sops, step-ca, …)
modules/drivers/       GPU-/VM-Treiber
secrets/               sops-verschlüsselte Konfiguration (Server-only)
```

## machineProfiles

Jeder Host setzt in `hosts/<host>/host-packages.nix` die Schalter, die er will. Deklariert sind sie zentral in `modules/core/profiles.nix`. Beispiel `homedepot`:

```nix
machineProfiles = {
  server.enable        = true;
  desktop.enable       = false;
  reverseProxy.enable  = true;
  adguard.enable       = true;
  media.enable         = true;
  homesuite.enable     = true;
  sonarqube.enable     = true;
  gitea.enable         = true;
  dependencyTrack.enable = true;
  stepCa.enable        = true;
};
```

Das Module schaut intern via `lib.mkIf cfg.enable`, ob es sich überhaupt aktiv reinhängen darf. Damit kann ein Server `modules/server` importieren, ohne automatisch alle Dienste hochzufahren.

## Server (homedepot)

Liefert intern unter `*.nestlerlabs.at`:

- **Gitea** + Actions-Runner — mit Auto-Provisioner, der eine Security-Pipeline in alle Repos legt
- **SonarQube Community** (Docker) — statische Codeanalyse
- **Dependency Track** (Docker) — SBOM + Vuln-Tracking
- **HomeSuite** — eigenes ASP.NET-Backend + Vite-Frontend
- **Jellyfin** + **Audiobookshelf** (NAS-Mount via CIFS)
- **AdGuard Home** — DNS + Rewrites für die internen Domains
- **step-ca** — private ACME-CA, alle nginx-vhosts holen sich darüber automatisch Certs ([Client-Trust einrichten](./docs/trust-ca.md))
- **sops-nix** — alle Passwörter / Tokens (Postgres, Runner-Token, Provisioner-PAT, step-ca-Intermediate) liegen verschlüsselt im Repo

## Desktop (nvidia)

- Hyprland + Waybar + Rofi + SwayNC
- Stylix als Theming-Layer (Gruvbox-base)
- nvim via [nvf](https://github.com/notashelf/nvf) mit LSP, Telescope, NeoTree, Treesitter
- Custom-Scripts unter `modules/home/scripts/` (rofi-launcher, Screenshot, Cheatsheets, Web-Search)
- NAS-Mount, Stylish-Boot via Minegrub-Theme

## Build

```bash
# lokal
sudo nixos-rebuild switch --flake .#<host>

# vom Desktop auf den Server
nixos-rebuild switch --flake .#homedepot \
  --target-host jakob@192.168.1.119 \
  --build-host localhost \
  --sudo
```

Alias `fr` / `fu` rebuilden bzw. updaten — siehe `modules/home/zsh.nix`.

## Secrets-Setup

Wenn `secrets/secrets.yaml` fehlt, läuft alles mit Hardcoded-Defaults weiter — `modules/server/secrets.nix` aktiviert sich nur bei vorhandener Datei. Anleitung zum Anlegen liegt in `secrets/README.md`.

## Was noch offen ist

Siehe `todo.txt`.
