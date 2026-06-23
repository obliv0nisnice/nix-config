{pkgs}:
# Waybar-Helfer für die MacBook-Tastaturbeleuchtung. Der Asahi-Kernel legt das
# LED-Gerät kbd_backlight an; brightnessctl schreibt es ohne root über logind.
# Aufrufe: ohne Argument -> JSON-Status für Waybar; toggle/up/down -> Aktion und
# danach erneut JSON-Status (Waybar führt exec nach on-click/on-scroll neu aus).
pkgs.writeShellScriptBin "kbd-backlight" ''
  bctl="${pkgs.brightnessctl}/bin/brightnessctl --device=kbd_backlight"

  case "$1" in
    up)   $bctl -q set 1%+ ;;
    down) $bctl -q set 1%- ;;
    toggle)
      if [ "$($bctl get)" -eq 0 ]; then
        $bctl -q set 25%
      else
        $bctl -q set 0
      fi
      ;;
  esac

  # brightnessctl -m: name,class,wert,prozent,max  z.B. kbd_backlight,leds,0,0%,255
  IFS=, read -r _ _ _ pct _ < <($bctl -m)
  pct=''${pct%\%}

  # Visuellen Füllbalken (16 Segmente) für den Tooltip bauen; per Scrollen
  # über dem Modul wird die Helligkeit verstellt (on-scroll in waybar.nix).
  width=16
  filled=$(( pct * width / 100 ))
  bar=""
  i=0
  while [ "$i" -lt "$width" ]; do
    if [ "$i" -lt "$filled" ]; then bar="$bar█"; else bar="$bar░"; fi
    i=$(( i + 1 ))
  done

  # 󰌌 = Tastatur an, 󰌐 = Tastatur aus (durchgestrichen). Steuerung ist binär,
  # daher nur das Icon in der Leiste; Balken und Wert zeigt der Tooltip.
  if [ "$pct" -eq 0 ]; then cls=off; icon="󰌐"; else cls=on; icon="󰌌"; fi
  printf '{"text": "%s", "tooltip": "Tastaturbeleuchtung\\n[%s]  %s%%", "class": "%s"}\n' "$icon" "$bar" "$pct" "$cls"
''
