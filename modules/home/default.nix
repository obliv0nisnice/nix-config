{ lib, machineProfiles, ... }: {
  imports = [
    ./bash.nix
    ./bat.nix
    ./btop.nix
    ./fastfetch
    ./gh.nix
    ./git.nix
    ./nixvim
    ./stylix.nix
    ./zsh.nix
  ] ++ lib.optionals machineProfiles.desktop.enable [
    ../core/firefox
    ./gtk.nix
    ./hyprland
    ./kitty.nix
    ./rofi
    ./qt.nix
    ./scripts
    ./swaync.nix
    ./virtmanager.nix
    ./waybar.nix
    ./wlogout
    ./xdg.nix
  ];
}
