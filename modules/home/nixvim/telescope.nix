{
  plugins.telescope = {
    enable = true;
    keymaps = {
      "<leader>sg" = "live_grep";
      "<leader>sf" = {
        action = "find_files";
        options.desc = "[S]earch [F]iles";
      };
      "<leader>gf" = {
        action = "git_files";
        options.desc = "Search [G]it [F]iles";
      };
      "<leader><space>" = {
        action = "buffers";
        options.desc = "List buffers";
      };
    };
    extensions.fzf-native = { enable = true; };
  };
}
