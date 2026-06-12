# Apple-Silicon-only (aarch64 / Asahi) modules. Imported exclusively by the
# macbook host on top of modules/core. The asahi kernel + bootloader chain
# itself comes from inputs.nixMac.nixosModules.apple-silicon-support (wired in
# flake.nix); this directory holds the Mac-specific tuning on top of it.
{ ... }:
{
  imports = [
    ./boot.nix
    ./emulateboot.nix
    ./ram.nix
    ./k3s-single-node.nix
    ./mullvad.nix
    ./netbird.nix
    ./touchid
  ];
}
