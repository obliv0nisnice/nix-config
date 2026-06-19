{
  plugins = {
    web-devicons.enable = true;
    nvim-tree = {
      enable = true;
      openOnSetup = true;
      settings = {
        "auto_reload_on_write" = true;
        "update_focused_file".enable = true;
        tab.sync = {
          close = true;
          open = true;
        };
      };
    };
  };
}
