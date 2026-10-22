{inputs, ...}: {
  imports = [
    ./profiles.nix
    ./profiles-from-vars.nix
    ./boot.nix
    ./fonts.nix
    ./hardware.nix
    ./network.nix
    ./nh.nix
    ./packages.nix
    ./services.nix
    ./stylix.nix
    ./system.nix
    ./user.nix
    ./virtualisation.nix
    ./xdg.nix
    ./fingerprint.nix
    ./netbird.nix
    ./NixOS-Sec-Toolbox
    inputs.stylix.nixosModules.stylix
    ./customConf
    ./Proxychains
  ];
}
