{pkgs}:
pkgs.writeShellScriptBin "nvim-cheatsheet" ''
  if pidof rofi > /dev/null; then
    pkill rofi
  fi

  msg='nvim Shortcuts (Leader = Space)  ·  ESC schließt das Menü'

  bindings=$(cat <<'EOF'
jk                           Insert -> Normal (statt ESC)
i / a / o                    Insert vor / nach Cursor / neue Zeile
v / V / Ctrl-v               Visual / Visual Line / Visual Block
dd  /  yy  /  p              Zeile löschen / yanken / paste
u  /  Ctrl-r                 undo / redo
gg  /  G                     Anfang / Ende der Datei
:w  /  :q  /  :wq  /  :q!    speichern / quit / beides / force quit

<Leader>e                    Neotree toggle (File Explorer)
<Leader>fe                   Neotree toggle (alternativ)
<Leader>ff                   Telescope: Datei nach Name finden
<Leader>lg                   Telescope: Live-Grep durchs Projekt
<Leader>nh                   Suchhervorhebung löschen

Ctrl-h / Ctrl-j / Ctrl-k / Ctrl-l    Insert-Mode Pfeile (Left/Down/Up/Right)

K                            LSP Hover (Doku zum Symbol)
gd  /  gr                    Go to Definition / References
<Leader> + ca                Code Action (über Trouble / fastaction)
[d  /  ]d                    Diagnostics: vorheriges / nächstes

<Leader>?                    WhichKey: alle Bindings anzeigen
<Leader>cs                   nvf Cheatsheet (eingebaut)

Visual: y / d / c            yank / delete / change Auswahl
Visual: >  /  <              Auswahl ein- / ausrücken

Hop / Leap (Motion):
s + Buchstaben               Springe zur Stelle (Leap)
<Leader>hw                   Hop: Wort
<Leader>hl                   Hop: Zeile

Treesitter:
:TSPlaygroundToggle          Syntax-Tree anschauen

Markdown:
:MarkdownPreviewToggle       Vorschau toggeln
EOF
)

  echo "$bindings" | rofi -dmenu -i -config ~/.config/rofi/config-long.rasi -mesg "$msg" -p "nvim"
''
