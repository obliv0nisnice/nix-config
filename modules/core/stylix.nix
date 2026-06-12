{pkgs, ...}: {
  # Styling Options
  stylix = {
    enable = true;
    image = ../../wallpapers/Legend_of_Zelda.png;
    # Gruvbox Dark Soft – angepasstes Orange (base09)

    base16Scheme = {
      # Baseline (Background / Foreground)
      base00 = "282828"; # Hintergrund dunkel
      base01 = "3c3836";
      base02 = "504945";
      base03 = "665c54";
      base04 = "bdae93";
      base05 = "d4be98"; # Standard-Foreground
      base06 = "ebdbb2";
      base07 = "fbf1c7";

      # Akzentfarben – kein Orange, frisches sattes Grün, ohne Graugrün
      base08 = "7b6651"; # Braunoliv (fein für Errors)
      base09 = "a4998f"; # Warmes, neutrales Beige-Braun (kein Grün, kein Grau)
      base0A = "a89984"; # Blasses Beige als mildes Gelb
      base0B = "2f7d32"; # Frisches sattes Waldgrün (ohne Grau)
      base0C = "82b3a8"; # Sanftes Aqua
      base0D = "729da5"; # Gedämpftes Blau
      base0E = "a2829a"; # Sanftes Violett
      base0F = "4a6b3e"; # Sattes, etwas helleres Moosgrün
    };

    polarity = "dark";
    opacity.terminal = 1.0;
    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 24;
    };
    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrains Mono";
      };
      sansSerif = {
        package = pkgs.montserrat;
        name = "Montserrat";
      };
      serif = {
        package = pkgs.montserrat;
        name = "Montserrat";
      };
      sizes = {
        applications = 12;
        terminal = 15;
        desktop = 11;
        popups = 12;
      };
    };
  };
}
