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
- `sep-getstatus-handshake.patch` — **⭐ FIX (2026-08-13, LIVE auf M1/t8103 via m1n1-Proxy
  bestätigt):** sendet vor `MSG_BOOT_TZ0` einen **`GET_STATUS`-Ping (type 0x2)** und wartet auf
  **`STATUS_OK` (0x66)** — die exakte Sequenz aus m1n1s funktionierendem `hw/sep.py::boot()`.
  Der Asahi-Stub feuerte TZ0 **blind** → der SEP-ROM blieb still. Der SEP **antwortet** aufs
  Boot-Protokoll (kein Reset/PMGR nötig — die frühere „CPU-reset"-These war falsch). Ablauf:
  `start()`→GET_STATUS; STATUS_OK→TZ0; TZ0_ACK2→GET_STATUS; 2. STATUS_OK→IMG4/SHMEM.
  Ersetzt die alten `sep-getrand-probe.patch` + `sep-cpu-reset.patch` (bleiben als Referenz im Repo).
- `fingerprint.nix`  — `services.fprintd` (userspace). Bringt erst etwas, wenn ein
  SEP-/SBIO-Treiber existiert (Reverse-Engineering, offen).

## Status (Kurzfassung)
SEP-Node aktiviert + `dt_set_sep()`-Injektion via Alias. **Neu: `sep-getstatus-handshake.patch`**
behebt die Stille auf TZ0: der SEP will vor TZ0 einen `GET_STATUS`-Ping + `STATUS_OK`. Live auf
einem M1 (t8103) über den m1n1-Proxy als funktionierende Sequenz bewiesen. **Zu testen am M2:**
bauen + booten, dann im `sep`-dyndbg-Log prüfen, ob der SEP jetzt antwortet. SBIO-Endpoint (0x08)
für Touch ID ist ein separates, offenes RE-Projekt (SEPOS advertised ihn erst on-demand). Volle RE:
`~/Projects/MacFingerprint` (`findings/phase3a-m1n1-sep-vs-asahi.md`, `PROGRESS.md`).

## Testen (am M2)
Kernel = `asahi-7.1.5-2` (flake nixMac). `sep-getstatus-handshake.patch` ist gegen 7.1.5-sep.rs +
die 3 Trace-Patches (discover-log/trace-rx/trace-tx) rebased; alle applizieren sauber (dry-run ok).
```
sudo nixos-rebuild boot --flake /home/oblivion/nix-config#macbook   # baut linux-asahi (dauert)
# (oder dein üblicher `nh`-Weg). Flake liegt in ~/nix-config, NICHT ~/NixOS.
# reboot in NixOS, dann:
sudo dmesg | grep -iE "SEP (TX|RX)|Got endpoint|Unknown boot"
```
Erwartung bei Erfolg (Log-Reihenfolge):
`SEP TX: GET_STATUS` → `SEP RX: ep=0xff type=0x66` (STATUS_OK) → `SEP TX: boot TZ0` →
`SEP RX 0x69`/`0xd2` → 2. `GET_STATUS`/`0x66` → `SEP TX: boot IMG4`+`set shmem` → `RX 0x6a` →
`Got endpoint ...` (Discovery). **Bleibt es schon bei GET_STATUS still** → der SEP antwortet auf
diesem t6020 gar nicht; dann zuerst m1n1-Proxy `sep.boot()` am M2 gegentesten (boot.bin-Swap auf
den debugusb-Build, wie beim M1), bevor weiter am Treiber gedreht wird.
