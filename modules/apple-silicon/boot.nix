# Begrenzt die Zahl der GRUB-Boot-Generationen. Die /boot-ESP ist nur 476M groß;
# pro Generation ~92M (Kernel-Image + initrd), real passen ~3. Ohne Limit (Default:
# unbegrenzt) läuft /boot bei häufigen Rebuilds voll -> Bootloader-Install bricht mit
# "No space left on device" ab. Siehe ~/Projects/MacFingerprint (boot-esp Memo).
{ ... }:
{
  boot.loader.grub.configurationLimit = 3;
}
