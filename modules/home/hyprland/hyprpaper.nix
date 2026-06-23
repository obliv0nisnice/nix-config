{username, pkgs, ...}: {
  home.file.".config/hypr/hyprpaper.conf".source = pkgs.writeText "hyprpaper.conf" ''
    wallpaper {
      monitor = *
      path = /home/${username}/nix-config/wallpapers/Legend_of_Zelda.png
      fit_mode = cover
    }
  '';
}
