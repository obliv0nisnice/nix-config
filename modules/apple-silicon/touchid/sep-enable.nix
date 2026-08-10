# Enable the Secure Enclave (SEP) device-tree node so the sep.ko boot stub
# probes. Touch ID reverse-engineering, step 3 (~/Projects/MacFingerprint).
#
# Why a build-time kernel patch (not hardware.deviceTree.overlays / configfs):
#   - m1n1 loads the DTB directly from ${kernel}/dtbs/apple/, so NixOS
#     hardware.deviceTree.overlays has no effect on this platform.
#   - CONFIG_OF_CONFIGFS (runtime configfs DT overlays) does not exist in the
#     asahi/mainline kernel.
# So we patch the DTS: in t602x-die0.dtsi the sep node goes disabled -> okay.
# boot.kernelPatches is forwarded into linux-asahi by apple-silicon-support.
{ ... }:
{
  boot.kernelPatches = [
    {
      name = "enable-sep-node";
      patch = ./sep-enable.patch;
    }
    {
      # Debug: log SEP endpoints during EP_DISCOVER (Phase 2 prep, confirm SBIO 0x08).
      name = "sep-discover-log";
      patch = ./sep-discover-log.patch;
    }
    {
      # Debug: log EVERY inbound SEP message (ep/type/msg0) to see how far boot gets.
      name = "sep-trace-rx";
      patch = ./sep-trace-rx.patch;
    }
    {
      # Debug: log every OUTBOUND boot message (TZ0/IMG4/SET_SHMEM + addresses).
      name = "sep-trace-tx";
      patch = ./sep-trace-tx.patch;
    }
    {
      # Diag: send a getrandom (EP 0xff cmd 16) before TZ0 in sep.rs start() -- the
      # one safe point (SEP power domain on). RX type 0x74 => SEP awake at probe;
      # silent => asleep by the time Linux can reach it (MacFingerprint Touch ID RE).
      name = "sep-getrand-probe";
      patch = ./sep-getrand-probe.patch;
    }
    {
      # FIX (MacFingerprint, statische RE von AppleA7IOP-ASCWrap-v4): SEP-Coprocessor
      # VOR TZ0 per ASC CPU_CONTROL (sep-reg0 + 0x44, Bit4=RUN) resetten. iBoot bootet
      # den SEP schon -> SEPROM ignoriert TZ0 sonst (Stille). AP-zugaengliche ASC-MMIO,
      # NICHT das gesperrte PMGR-Register. Details: findings/phase2d-asc-mailbox-registers.md.
      name = "sep-cpu-reset";
      patch = ./sep-cpu-reset.patch;
    }
  ];
  # iomem=relaxed: schaltet IO_STRICT_DEVMEM fuer nicht-EXCLUSIVE-Regionen ab,
  # damit /dev/mem die SEP-ASC-Register lesen/schreiben kann WAEHREND apple_sep
  # gebunden+gepowert ist (Live-Debug der SEP-Bring-up-Sequenz, MacFingerprint).
  # Kein Kernel-Recompile, nur Reboot. Spaeter wieder entfernen.
  # pd_ignore_unused: genpd soll ungenutzte Power-Domains NICHT abschalten. Der sep-
  # Treiber ist ein Modul (laedt spaet) -> beim genpd-"disable unused" hat die SEP-Domain
  # keinen Consumer -> wuerde abgeschaltet -> SEP verliert Power (in m1n1 war er wach).
  # Test: Domain durchgehend an lassen, damit der SEP wach bleibt (MacFingerprint Touch ID RE).
  # clk_ignore_unused: Pendant zu pd_ignore_unused fuer Clocks. Letzter "Linux gatet
  # ungenutzte Ressource weg"-Hebel; schliesst Clock-Gating als SEP-Schlaf-Ursache aus.
  # UMKEHR (2026-08-10, MacFingerprint): pd_ignore_unused/clk_ignore_unused ENTFERNT.
  # Statische RE zeigte: der SEP-CPU-Reset ist AP-seitig weder per Register (ASC-CPU-Control
  # geschuetzt/liest 0) noch per Mailbox-Control-Msg moeglich -> einziger Reset-Hebel ist ein
  # Power-Cycle der Domain ps_sep (SEP off->on = Kaltstart -> SEPROM -> akzeptiert TZ0). Genau
  # das verhinderte pd_ignore_unused. Ohne die Flags cycled genpd ps_sep beim "disable-unused"
  # (kein Consumer, sep.ko laedt spaet) ab und beim sep.ko-Probe wieder an. TEST dieser Hypothese.
  boot.kernelParams = [ "sep.dyndbg=+p" "iomem=relaxed" ];

  # m1n1-Override ENTFERNT (2026-06-16): Diagnose ergab, der SEP ist auch in m1n1
  # (early UND late) tot -> iBoot legt ihn schlafen, bevor irgendein OS-Code laeuft.
  # m1n1 bringt also keinen Vorteil ggue. Linux; Override raus = stock m1n1, schneller
  # brick-freier Boot. Patch-Datei m1n1-septest.patch bleibt im Repo (Referenz).
  # Naechster Schritt: Wake/Re-Bootstrap-Sequenz (AppleSEPManager) -> in Linux umsetzen.
}
