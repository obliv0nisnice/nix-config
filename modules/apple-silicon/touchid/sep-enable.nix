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
      # ⭐ FIX (MacFingerprint 2026-08-13, LIVE auf M1/t8103 via m1n1-Proxy verifiziert):
      # GET_STATUS-Handshake VOR TZ0. m1n1s funktionierender hw/sep.py::boot() pingt
      # GET_STATUS (type 0x2) und wartet auf STATUS_OK (0x66) VOR TZ0 (und nochmal vor IMG4);
      # der Asahi-Stub feuerte TZ0 blind -> der SEP-ROM blieb still. Der SEP ANTWORTET auf
      # das Boot-Protokoll (kein Reset/PMGR noetig -- die alte "CPU-reset"-These war falsch).
      # start()->GET_STATUS; STATUS_OK->TZ0; TZ0_ACK2->GET_STATUS; 2. STATUS_OK->IMG4/SHMEM.
      # Ersetzt sep-getrand-probe + sep-cpu-reset. Details: findings/phase3a-m1n1-sep-vs-asahi.md.
      name = "sep-getstatus-handshake";
      patch = ./sep-getstatus-handshake.patch;
    }
  ];
  # sep.dyndbg=+p: aktiviert die dev_dbg/dev_info-Logs im sep-Treiber, damit wir den
  # Handshake sehen: "SEP TX: GET_STATUS" -> "SEP RX: ep=0xff type=0x66" (STATUS_OK) ->
  # "SEP TX: boot TZ0" -> RX 0x69/0xd2 -> 2. GET_STATUS/STATUS_OK -> IMG4/SHMEM -> RX 0x6a ->
  # "Got endpoint ..." (Discovery). Bleibt bei GET_STATUS still => SEP antwortet auf diesem
  # Geraet gar nicht (dann erst m1n1-Proxy sep.boot() gegentesten). MacFingerprint Touch ID RE.
  # (iomem=relaxed / pd_ignore_unused entfernt: waren fuer den /dev/mem-Survey bzw. die
  #  widerlegte Power-Cycle-These -- der SEP braucht keinen Reset, nur den GET_STATUS-Ping.)
  boot.kernelParams = [ "sep.dyndbg=+p" ];

  # m1n1-Override ENTFERNT (2026-06-16): Diagnose ergab, der SEP ist auch in m1n1
  # (early UND late) tot -> iBoot legt ihn schlafen, bevor irgendein OS-Code laeuft.
  # m1n1 bringt also keinen Vorteil ggue. Linux; Override raus = stock m1n1, schneller
  # brick-freier Boot. Patch-Datei m1n1-septest.patch bleibt im Repo (Referenz).
  # Naechster Schritt: Wake/Re-Bootstrap-Sequenz (AppleSEPManager) -> in Linux umsetzen.
}
