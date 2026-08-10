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
- `sep-cpu-reset.patch` — **FIX (2026-08-10):** resettet den SEP-Coprocessor VOR `MSG_BOOT_TZ0`
  über das ASC-Register `CPU_CONTROL` (sep-reg0 `0x396400000` + `0x44`, Bit4 = RUN). Grund:
  iBoot hat den SEP schon gebootet → seine SEPROM ignoriert TZ0 → SEP bleibt still. Der Reset
  liegt auf **AP-zugänglicher ASC-MMIO**, NICHT dem gesperrten PMGR-Register (das crashte früher).
  Quelle: statische RE von `AppleA7IOP-ASCWrap-v4` (`_runCPU`/`stopCPU`).
- `fingerprint.nix`  — `services.fprintd` (userspace). Bringt erst etwas, wenn ein
  SEP-/SBIO-Treiber existiert (Reverse-Engineering, offen).

## Status (Kurzfassung)
SEP-Node aktiviert + `dt_set_sep()`-Injektion via Alias. **Neu: `sep-cpu-reset.patch`** soll die
bisherige Stille auf TZ0 beheben (SEP-CPU-Reset vor dem Boot-Handshake). **Zu testen:** bauen +
booten, dann im `sep`-dyndbg-Log prüfen, ob nach „ASC CPU reset … before TZ0" jetzt eine SEP-
Antwort (TZ0_ACK1/ACK2 = type 0x69/0xD2 über `sep-trace-rx`) kommt. Danach SBIO-Endpoint (0x08)
für Touch ID drauf implementieren. Vollständige RE/Register-Map: `~/Projects/MacFingerprint`
(`findings/phase2d-asc-mailbox-registers.md`, `PROGRESS.md`).

## Testen
```
sudo nixos-rebuild boot --flake /home/oblivion/NixOS#macbook   # baut linux-asahi (dauert)
# reboot in NixOS, dann:
sudo dmesg | grep -iE "SEP|sep:"        # "ASC CPU reset ... before TZ0" + TZ0 + evtl. ACKs
```
Erwartung bei Erfolg: nach dem CPU-Reset beantwortet der SEP TZ0 (RX 0x69/0xD2), dann läuft der
IMG4/SET_SHMEM-Handshake. Bleibt es still → `phase2d`-„zu verifizieren" durchgehen (reg0-vs-reg1,
Bit-Semantik, ggf. kleine Verzögerung nach runCPU).
