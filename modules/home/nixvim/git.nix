{
  plugins = {
    diffview = { enable = true; };
    lazygit = { enable = true; };
    neogit = {
      enable = true;
      config.integrations = { diffview = true; };
    };
    gitsigns = {
      enable = true;
      config = {
        current_line_blame = true;
        trouble = true;
      };
    };
  };
}
