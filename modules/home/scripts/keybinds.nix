{pkgs}:
pkgs.writeShellScriptBin "list-keybinds" ''
  # check if rofi is already running
  if pidof rofi > /dev/null; then
    pkill rofi
  fi

  msg='☣️ NOTE ☣️: Clicking with Mouse or Pressing ENTER will have NO function'
  keybinds=$(grep -E '^\s*(hl\.)?bind\(' ~/.config/hypr/hyprland.lua)

  # use rofi to display the keybinds with the modified content
  echo "$keybinds" | rofi -dmenu -i -config ~/.config/rofi/config-long.rasi -mesg "$msg"

''
