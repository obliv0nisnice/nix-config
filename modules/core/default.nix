{inputs, ...}: {
  imports = [
    ./profiles.nix
    ./boot.nix
    ./fonts.nix
    ./hardware.nix
    ./network.nix
    ./nh.nix
    ./packages.nix
    ./services.nix
    #./starfish.nix
    ./stylix.nix
    ./system.nix
    ./user.nix
    ./virtualisation.nix
    ./xdg.nix
    ./fingerprint.nix
    ./NixOS-Sec-Toolbox
    inputs.stylix.nixosModules.stylix
    ./customConf
    ./Proxychains
  ];
}
