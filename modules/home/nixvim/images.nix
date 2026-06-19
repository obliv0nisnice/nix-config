{ pkgs, ... }:
{
  plugins = {
    image.enable = true;
    clipboard-image = {
      # todo change based on graphical settings
      clipboardPackage = pkgs.wl-clipboard;
      enable = true;
      settings = {
        typst = {
          affix = ''#image("%s")'';
        };
      };
    };
  };
}
