{ ... }:
{
  imports = [
    # TODO: Platzhalter mit fremden Disk-UUIDs. Auf der Maschine ersetzen:
    #   nixos-generate-config --show-hardware-config > hosts/arbeit/hardware.nix
    # und hier ./hardware.nix importieren.
    ../default/hardware.nix
    ./host-packages.nix
  ];
}
