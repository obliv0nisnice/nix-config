{
  pkgs,
  username,
  inputs,
  ...
}: {
  home.packages = with pkgs; [
    awww
    grim
    hyprshot
    slurp
    wl-clipboard
    swappy
    ydotool
    dunst
    wl-clipboard
  ];
  systemd.user.targets.hyprland-session.Unit.Wants = [
    "xdg-desktop-autostart.target"
  ];
  wayland.windowManager.hyprland = {
    enable = true;
    # Lua-Config (hyprland.lua) – hyprlang ist seit Hyprland 0.55 deprecated.
    configType = "lua";
    xwayland = {
      enable = true;
    };
    systemd.enable = true;
  };
  # Place Files Inside Home Directory
  home.file."Pictures/Wallpapers" = {
    source = ../../../wallpapers;
    recursive = true;
  };
  home.file.".face.icon".source = ./dark_angel_as_hacker.png;
  home.file.".config/face.jpg".source = ./dark_angel_as_hacker.png;
  home.file.".config/swappy/config".text = ''
    [Default]
    save_dir=/home/${username}/Pictures/Screenshots
    save_filename_format=swappy-%Y%m%d-%H%M%S.png
    show_panel=false
    line_size=5
    text_size=20
    text_font=Ubuntu
    paint_mode=brush
    early_exit=true
    fill_shape=false
  '';
}
