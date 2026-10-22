# Rider-Look: vscode.nvim (volle Treesitter- und LSP-Semantic-Token-Unterstützung)
# mit den Farben aus Riders Dark-Theme statt der VS-Code-Palette.
let
  rider = {
    bg = "#262626";
    fg = "#BDBDBD"; # Text, lokale Variablen, Parameter
    keyword = "#6C95EB";
    string = "#C9A26D";
    number = "#ED94C0";
    comment = "#85C46C";
    type = "#C191FF"; # Klassen, Typen
    struct = "#E1BFFF"; # Structs, Enums
    method = "#39CC8F"; # Funktionen, Methoden
    field = "#66C3CC"; # Felder, Properties, Nix-Attributnamen
  };
in
{
  colorschemes.vscode = {
    enable = true;
    settings = {
      style = "dark";
      italic_comments = true;

      # Palette von vscode.nvim auf Rider umgefärbt (Namen aus vscode.nvim/colors.lua).
      color_overrides = with rider; {
        vscBack = bg;
        vscFront = fg;
        vscBlue = keyword;
        vscPink = keyword; # Rider färbt auch if/return/import wie alle Keywords
        vscOrange = string;
        vscLightGreen = number;
        vscGreen = comment;
        vscBlueGreen = type;
        vscYellow = method;
        vscLightBlue = field;
      };

      group_overrides = with rider; {
        # Wie in Rider: Locals/Parameter neutral, Members farbig.
        "@variable".fg = fg;
        "@variable.parameter".fg = fg;
        "@module".fg = fg; # Namespaces
        "@lsp.type.struct".fg = struct;
        "@lsp.type.enum".fg = struct;
        # Nix: Pfade wie ./foo.nix vom normalen String absetzen.
        "@string.special.path" = {
          fg = string;
          underline = true;
        };
      };
    };
  };
}
