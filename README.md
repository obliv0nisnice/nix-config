# nix-config

My NixOS setup for several machines — Hyprland desktops, a laptop, throwaway VMs and a self-hosted home server. One flake, shared modules, per-host you just flip switches.

## Hosts

| Host | What it is |
|---|---|
| `nvidia` | Main desktop — Hyprland, GPU for games / AI |
| `nvidia-laptop` | Laptop with Nvidia Prime |
| `amd` / `intel` / `vm` | More machines / test boxes |
| `homedepot` | Home server — Gitea, SonarQube, Dependency Track, Jellyfin, AdGuard, step-ca |
| `macbook` | Apple Silicon (Asahi), aarch64 |

```bash
sudo nixos-rebuild switch --flake .#<host>
```

## Layout

```
flake.nix              Inputs + host definitions
profiles/_common.nix   Shared imports for every profile
profiles/<name>/       Per-profile driver / module choices
hosts/<host>/          hardware file, variables.nix, host-packages.nix
modules/core/          System base (boot, network, packages, services, stylix)
modules/home/          Home-Manager (Hyprland, Waybar, nvim, Rofi, scripts)
modules/server/        Server services (nginx, AdGuard, Gitea, sops, step-ca …)
modules/apple-silicon/ Asahi / Mac-specific tuning
modules/drivers/       GPU / VM drivers
```

## How a host is configured

Everything that gives a host its personality lives in **`hosts/<host>/variables.nix`** — browser, keyboard layout, monitors, and a full set of feature toggles. Every option is listed explicitly so you can flip things on and off at a glance.

```nix
# hosts/<host>/variables.nix
{
  browser = "floorp";
  keyboardLayout = "de";

  profiles = {
    desktop = { enable = true; gaming.enable = true; printing.enable = true; /* … */ };
    server  = { enable = false; reverseProxy.enable = false; gitea.enable = false; /* … */ };
    network = { remoteAccess.enable = true; vpn.enable = false; /* … */ };
    security = { enable = false; pentest.enable = false; /* … */ };
    apple   = { x86Emulation.enable = false; /* … */ };
    virtualization.enable = true;
    dev.dotnet.enable = false;
  };

  customConf = { nasMount.enable = false; fingerprint.enable = false; };
}
```

A small bridge (`modules/core/profiles-from-vars.nix`) feeds this plain data into the `machineProfiles` / `customConf` option trees declared in `modules/core/profiles.nix`. Modules then guard themselves with `lib.mkIf cfg.enable`, so importing `modules/server` doesn't start every service — only the ones switched on. `host-packages.nix` is left for truly host-specific packages.

## Server (homedepot)

Served internally under `*.nestlerlabs.at`:

- **Gitea** + Actions runner — auto-provisions a security pipeline into every repo
- **SonarQube** (Docker) — static analysis · **Dependency Track** (Docker) — SBOM + vuln tracking
- **HomeSuite** — own ASP.NET backend + Vite frontend
- **Jellyfin** + **Audiobookshelf** (NAS over CIFS) · **AdGuard Home** — DNS + rewrites
- **step-ca** — private ACME CA; nginx vhosts pull certs automatically ([trust setup](./docs/trust-ca.md))
- **sops-nix** — every secret (Postgres, runner token, provisioner PAT, CA intermediate) encrypted in-repo

## Desktop

Hyprland + Waybar + Rofi + SwayNC, themed with Stylix. Neovim via nixvim (LSP, Telescope, nvim-tree, Treesitter). Custom scripts under `modules/home/scripts/`, NAS mount, Minegrub boot theme.

## Build

```bash
# local
sudo nixos-rebuild switch --flake .#<host>

# desktop -> server
nixos-rebuild switch --flake .#homedepot \
  --target-host jakob@192.168.1.119 --build-host localhost --sudo
```

Shell aliases `fr` / `fu` rebuild / update — see `modules/home/zsh.nix`.

## Secrets

If `secrets/secrets.yaml` is absent everything still builds on hardcoded defaults — `modules/server/secrets.nix` only activates when the file exists. See `secrets/README.md`.
