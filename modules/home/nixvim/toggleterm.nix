{
  plugins.toggleterm = {
    enable = true;
    settings = {
      # config -> settings (nixvim-Umbenennung; mit "config" wurde setup({}) leer
      # generiert -> Mapping fehlte -> Terminal ging nicht auf).
      # open_mapping wird roh als Lua emittiert, daher das Lua-String-Literal
      # [[<C-t>]] (entspricht "<C-t>"); ein nackter String würde unquotiert raus.
      open_mapping = "[[<C-t>]]";
    };
  };
}
