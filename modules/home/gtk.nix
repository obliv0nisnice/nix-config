{ config, pkgs, lib, ... }:

{
  gtk = {
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    # Mirror the (stylix-provided) gtk3 theme onto gtk4. Current stylix also sets
    # gtk4.theme.package itself, so force this to resolve the duplicate definition.
    gtk4.theme = lib.mkForce config.gtk.theme;
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };
}
