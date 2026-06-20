{
  pkgs,
  username,
  ...
}: {
  home.packages = [
    (import ./emopicker9000.nix {inherit pkgs;})
    (import ./keybinds.nix {inherit pkgs;})
    (import ./nvim-cheatsheet.nix {inherit pkgs;})
    (import ./task-waybar.nix {inherit pkgs;})
    (import ./squirtle.nix {inherit pkgs;})
    (import ./nvidia-offload.nix {inherit pkgs;})
    #(import ./wallsetter.nix {
    #  inherit pkgs;
    #  inherit username;
    #}) -> ersetzt mit hyprpaper
    (import ./web-search.nix {inherit pkgs;})
    (import ./rofi-launcher.nix {inherit pkgs;})
    (import ./screenshootin.nix {inherit pkgs;})
    (import ./kbd-backlight.nix {inherit pkgs;})
  ];
}
