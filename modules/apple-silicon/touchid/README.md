# modules/core/touchid

Touch-ID-/SEP-Vorhaben für das MacBook Pro 14" M2 Pro (t6020) unter Asahi/NixOS.

> Vollständige Doku, Logbuch & Befunde: **`~/Projects/MacFingerprint`** (PROGRESS.md).

## Dateien
- `default.nix`      — bündelt die Imports unten.
- `sep-enable.nix`   — `boot.kernelPatches` mit `sep-enable.patch`.
- `sep-enable.patch` — DTS-Patch am Board (`t6020-j414s.dts`): setzt den SEP-Node
  `status = "okay"` und fügt einen `sep`-Alias hinzu. Der Alias ist nötig, damit
  m1n1 `dt_set_sep()` die `sepfw`-Reserved-Memory-Region + iboot/local-policy-
  Manifests injiziert — sonst scheitert das `sep.ko`-Probe mit `-EINVAL (-22)`.
- `fingerprint.nix`  — `services.fprintd` (userspace). Bringt erst etwas, wenn ein
  SEP-/SBIO-Treiber existiert (Reverse-Engineering, offen).

## Status (Kurzfassung)
SEP-Node wird aktiviert; m1n1 1.5.2 kann via `dt_set_sep()` injizieren (Alias war
der fehlende Baustein). Ziel: SEP-Boot-Stub probt, dann SBIO-Endpoint (Touch ID)
reverse-engineeren. Details/aktueller Schritt siehe Projekt-PROGRESS.md.
