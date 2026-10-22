# RTX 5060 Ti (Blackwell) läuft nur mit den offenen NVIDIA-Kernelmodulen.
# Erst nach dem Kartentausch einschalten – ältere Karten (vor Turing) gehen
# mit open = true nicht.
{ config, lib, ... }:
let
  gpu = config.machineProfiles.server.assistant.gpu.enable;
in
{
  config = lib.mkMerge [
    (lib.mkIf gpu {
      drivers.nvidia.enable = true;
      hardware.nvidia.open = true;
    })

    # Bis zum Tausch: die alte Karte (vor Turing) wird ab Treiberserie 590 nicht
    # mehr unterstützt -> letzte passende Serie 580.
    (lib.mkIf (!gpu && config.drivers.nvidia.enable) {
      hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    })
  ];
}
