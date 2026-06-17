{pkgs}:
pkgs.writeShellScriptBin "nvim-cheatsheet" ''
  if pidof rofi > /dev/null; then
    pkill rofi
  fi

  msg='nvim Shortcuts (Leader = Space)  ·  von allgemein → speziell  ·  ESC schließt'

  bindings=$(cat <<'EOF'
══ 1. BEWEGEN (nur Tastatur) ══
h / j / k / l                links / runter / hoch / rechts
w / b                        ein Wort vor / zurück
e                            ans Wortende
0                            an den Zeilenanfang (Spalte 0)
^                            erstes Zeichen der Zeile
$                            ans Zeilenende
gg                           an den Dateianfang
G                            ans Dateiende
{ / }                        Absatz hoch / runter
Ctrl-u / Ctrl-d              halbe Seite hoch / runter
Ctrl-b / Ctrl-f              ganze Seite hoch / runter
H / M / L                    Bildschirm oben / Mitte / unten
%                            zur passenden Klammer springen
f / F                        zu einem Zeichen springen (Hop)
:42                          zu Zeile 42 springen

── im Dateibaum (nvim . öffnet ihn, sonst <Leader>x) ──
j / k                        im Baum hoch / runter
Enter  oder  o               Datei öffnen (Fokus springt in die Datei)
<Tab>                        Datei nur vorschauen (Fokus bleibt im Baum)
Ctrl-w l                     vom Baum in die geöffnete Datei wechseln
Ctrl-w h                     aus der Datei zurück in den Baum
Ctrl-w w                     zwischen Baum und Datei hin- und herspringen
Backspace                    Ordner zuklappen
P                            zum übergeordneten Ordner
-                            eine Verzeichnisebene nach oben
Ctrl-v / Ctrl-x / Ctrl-t     öffnen in V-Split / H-Split / neuem Tab
a                            Datei/Ordner anlegen (mit / am Ende = Ordner)
d                            löschen
r                            umbenennen
x / c / p                    ausschneiden / kopieren / einfügen
H                            versteckte Dateien (Dotfiles) ein/aus
R                            Baum neu laden
q                            Baum schließen
g?                           Hilfe: alle Baum-Tasten anzeigen

══ 2. MODUS WECHSELN ══
i / a                        Insert vor / nach dem Cursor
I / A                        Insert am Zeilenanfang / -ende
o / O                        neue Zeile darunter / darüber
v                            Visual (Zeichen markieren)
V                            Visual Line (Zeilen markieren)
Ctrl-v                       Visual Block (Spalten markieren)
Esc                          zurück in den Normal-Modus

══ 3. BEARBEITEN (kopieren, einfügen, löschen) ══
yy                           Zeile kopieren (yank)
y                            (Visual) Auswahl kopieren
p                            nach dem Cursor einfügen
P                            vor dem Cursor einfügen
dd                           Zeile löschen (+ kopieren)
d                            (Visual) Auswahl löschen
x                            einzelnes Zeichen löschen
cc                           ganze Zeile ändern (löschen + Insert)
c                            (Visual) Auswahl ändern
r                            ein Zeichen ersetzen
u                            rückgängig (undo)
Ctrl-r                       wiederherstellen (redo)
.                            letzte Aktion wiederholen
>> / <<                      Zeile ein- / ausrücken
> / <                        (Visual) Auswahl ein- / ausrücken
(Zwischenablage = System, yank/paste teilen sie automatisch)

══ 4. SUCHEN & ERSETZEN ══
/text                        vorwärts suchen
?text                        rückwärts suchen
n / N                        nächster / voriger Treffer
:%s/alt/neu/g                alle Vorkommen ersetzen

══ 5. DATEIEN & SUCHE (Tree + Telescope) ══
<Leader>x                    Dateibaum (NvimTree) ein/aus
<Leader>sf                   Datei nach Name finden
<Leader>sg                   Live-Grep durchs Projekt
<Leader>gf                   Git-Dateien durchsuchen
<Leader><Space>              offene Buffer auflisten

══ 6. TABS / BUFFER ══
<Leader>tn                   neuen Tab öffnen
<Leader>td                   Tab schließen
<Leader>tt                   nächster Tab
<Leader>tp                   voriger Tab

══ 7. CODE / LSP (IDE-Funktionen) ══
K                            Doku zum Symbol (Hover)
gd                           zur Definition
gD                           zur Deklaration
gr                           Referenzen anzeigen
gI                           zur Implementierung
gT                           zur Typdefinition
<Leader>ca                   Code Action
<Leader>rn                   Symbol umbenennen
<Leader>ds                   Dokument-Symbole
<Leader>ws                   Workspace-Symbole
<Leader>fm                   Datei formatieren
<Leader>dt                   Diagnostics-Liste (Trouble)
Ctrl-k                       (Insert) Signatur-Hilfe

══ 8. VERVOLLSTÄNDIGUNG (blink.cmp) ══
Ctrl-Space                   Vorschläge anzeigen
Ctrl-n / Ctrl-p              nächster / voriger Vorschlag
Ctrl-j / Ctrl-k              dasselbe (Alternative)
Tab / Shift-Tab              auswählen / Snippet-Sprung
Enter                        Vorschlag übernehmen
Ctrl-e                       Menü schließen
Ctrl-d / Ctrl-f              Doku hoch / runter scrollen

══ 9. GIT ══
<Leader>gg                   LazyGit öffnen
<Leader>gc                   Änderungen committen (Neogit)
<Leader>gd                   Git-Änderungen ansehen (Diffview)
<Leader>gq                   Diffview schließen
<Leader>grh                  Hunk zurücksetzen
<Leader>grb                  ganzen Buffer zurücksetzen
<Leader>gtb                  Blame der aktuellen Zeile

══ 10. REFACTORING ══
<Leader>re                   zu Variable extrahieren
<Leader>rE                   zu Funktion extrahieren
<Leader>rb                   zu Block extrahieren
<Leader>ri                   Variable inlinen
<Leader>rI                   Funktion inlinen

══ 11. SONSTIGES ══
<Leader>p                    Bild aus Zwischenablage einfügen
<Leader>                     (kurz warten) which-key zeigt Folgetasten
:w  /  :q                    speichern / beenden
:wq  /  :q!                  speichern+beenden / ohne Speichern beenden
EOF
)

  echo "$bindings" | rofi -dmenu -i -config ~/.config/rofi/config-long.rasi -mesg "$msg" -p "nvim"
''
