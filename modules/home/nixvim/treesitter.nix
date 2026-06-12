{
  plugins = {
    treesitter = {
      enable = true;
      nixGrammars = true;
      config = {
        indent.enable = true;
      };
      highlight = {
        enable = true;
      };
    };
    #treesitter-context.enable = true;
    rainbow-delimiters.enable = true;
  };
}
