{pkgs}:
pkgs.writeShellScriptBin "emopicker9000" ''
  if pidof rofi > /dev/null; then
    pkill rofi
  fi
  ${pkgs.rofimoji}/bin/rofimoji --action copy --clipboarder wl-copy
''
