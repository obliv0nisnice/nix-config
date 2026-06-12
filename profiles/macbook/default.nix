{ host, ... }:
{
  imports = [
    ../../hosts/${host}
    ../../modules/core
    ../../modules/apple-silicon
  ];
  # No modules/drivers (x86 GPU stack) and no modules/server here — the asahi
  # kernel/bootloader come from apple-silicon-support (flake.nix) and the
  # Mac-specific tuning from modules/apple-silicon.
}
