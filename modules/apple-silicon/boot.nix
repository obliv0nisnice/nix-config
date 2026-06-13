# Begrenzt die Zahl der GRUB-Boot-Generationen. Die /boot-ESP ist nur 476M groß;
# pro Generation ~92M (Kernel-Image + initrd), real passen ~3. Ohne Limit (Default:
# unbegrenzt) läuft /boot bei häufigen Rebuilds voll -> Bootloader-Install bricht mit
# "No space left on device" ab. Siehe ~/Projects/MacFingerprint (boot-esp Memo).
{ config, lib, ... }:
{
  boot.loader.grub.configurationLimit = 3;
  #hardware.asahi.extractPeripheralFirmware = false;

  # Setzt den Firmware-Suchpfad als Kernel-Cmdline-Param. Sonst wird er nur vom
  # Stage-2-Aktivierungsskript (nixpkgs udev.nix) nach /sys/.../firmware_class/path
  # geschrieben — das rennt gegen das frühe Geräte-Probing: brcmfmac (WLAN) und
  # dockchannel-hid (Touchpad) fordern ihre Firmware bei ~3.6s an, das activate-Skript
  # setzt den Pfad erst bei ~3.5-4.5s -> ~50% der Kaltstarts: "Direct firmware load ...
  # failed with error -2" und WLAN+Touchpad sind tot. (modprobe.d/firmware.conf greift
  # nicht, weil der firmware_class-Loader im Asahi-Kernel builtin ist.) Als Cmdline-Param
  # liest der builtin-Loader den Pfad vor jedem Probe -> Race weg.
  boot.kernelParams = [ "firmware_class.path=${config.hardware.firmware}/lib/firmware" ];

  # nixpkgs erzwingt DEBUG_INFO (DWARF) + BTF im Kernel; bei 7500+ Modulen wird der
  # Build-Tree dadurch >40G und der Kernel-Build bricht auf der 155G-Partition mit
  # "No space left on device" ab. Die Symbole landen eh nicht im installierten Kernel.
  # Kostet: kein BTF, d.h. CO-RE-eBPF-Tools (bpftrace etc.) funktionieren nicht.
  boot.kernelPatches = [
    {
      name = "no-debug-info";
      patch = null;
      structuredExtraConfig = with lib.kernel; {
        DEBUG_INFO = lib.mkForce (option no);
        DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT = lib.mkForce (option no);
        DEBUG_INFO_BTF = lib.mkForce (option no);
        DEBUG_INFO_BTF_MODULES = lib.mkForce (option no);
        DEBUG_INFO_NONE = option yes;
        # Diese Optionen setzen BTF voraus und verschwinden ohne es aus dem Kconfig:
        NET_SCH_BPF = lib.mkForce (option no);
        SCHED_CLASS_EXT = lib.mkForce (option no);
      };
    }
  ];
}
