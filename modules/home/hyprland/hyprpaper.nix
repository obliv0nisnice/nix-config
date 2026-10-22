{username, pkgs, vars, lib, ...}: let
  wallpaper = vars.wallpaper or "Legend_of_Zelda.png";
  wallpapers = vars.wallpapers or { };
  dir = "/home/${username}/nix-config/wallpapers";
  block = monitor: file: ''
    wallpaper {
      monitor = ${monitor}
      path = ${dir}/${file}
      fit_mode = cover
    }
  '';
  # Default zuerst auf alle Bildschirme (*), danach die per-Monitor-Overrides.
  blocks = [ (block "*" wallpaper) ] ++ lib.mapAttrsToList block wallpapers;
in {
  home.file.".config/hypr/hyprpaper.conf".source =
    pkgs.writeText "hyprpaper.conf" (lib.concatStrings blocks);
}
