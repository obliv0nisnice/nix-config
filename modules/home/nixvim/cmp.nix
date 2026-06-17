# Completion via blink.cmp.
#
# Ersetzt nvim-cmp + cmp-* (cmp-nvim-lsp crasht auf Neovim 0.12:
# "source.lua:69: attempt to index field 'client' (a nil value)" -> die
# nvim_lsp-Quelle wird nicht registriert -> keine LSP-Vorschläge). blink ist
# aktiv gepflegt, hat LSP/Pfad/Snippet/Buffer als eingebaute Quellen.
{
  plugins = {
    luasnip.enable = true;
    copilot-lua = {
      enable = true;
      settings = {
        suggestion.enabled = false;
        panel.enabled = false;
      };
    };

    blink-cmp = {
      enable = true;
      settings = {
        snippets.preset = "luasnip";

        sources = {
          default = [
            "lsp"
            "path"
            "snippets"
            "buffer"
          ];
        };

        # Tastenbelegung wie zuvor unter nvim-cmp.
        keymap = {
          preset = "none";
          "<C-n>" = [ "select_next" "fallback" ];
          "<C-p>" = [ "select_prev" "fallback" ];
          "<C-j>" = [ "select_next" "fallback" ];
          "<C-k>" = [ "select_prev" "fallback" ];
          "<C-d>" = [ "scroll_documentation_up" "fallback" ];
          "<C-f>" = [ "scroll_documentation_down" "fallback" ];
          "<C-Space>" = [ "show" "show_documentation" "hide_documentation" ];
          "<C-e>" = [ "hide" "fallback" ];
          "<CR>" = [ "accept" "fallback" ];
          "<Tab>" = [ "select_next" "snippet_forward" "fallback" ];
          "<S-Tab>" = [ "select_prev" "snippet_backward" "fallback" ];
        };

        completion = {
          # Nicht automatisch vorauswählen (entspricht dem alten select = false).
          list.selection = {
            preselect = false;
            auto_insert = false;
          };
          documentation = {
            auto_show = true;
            auto_show_delay_ms = 200;
          };
          menu.border = "rounded";
        };
      };
    };
  };
}
