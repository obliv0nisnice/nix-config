{
  # Git Configuration ( For Pulling Software Repos )
  gitUsername = "oblivion";#"obliv0nisnice";
  gitEmail = "anrufen_nahm0p@icloud.com";

  # ---- Bildschirme & Wallpaper (alle Felder optional) ----
  # So sieht die Konfiguration aus:
  #
  #   # Monitore deklarativ – Liste von Hyprland-Monitorstrings
  #   # Format: "<output>,<breite>x<hoehe>@<hz>,<x>x<y>,<scale>"
  #   monitors = [
  #     "DP-1,2560x1440@144,0x0,1"
  #     "HDMI-A-1,1920x1080@60,2560x0,1"
  #   ];
  #   # Leer / weggelassen => automatischer Default (,preferred,auto,auto).
  #
  #   # Ein Wallpaper für alle Bildschirme (Dateiname aus wallpapers/)
  #   wallpaper = "Legend_of_Zelda.png";
  #   # Eigenes Wallpaper pro Bildschirm (Output-Name => Datei)
  #   wallpapers = {
  #     "DP-1" = "Itachi.jpg";
  #     "HDMI-A-1" = "grogu.jpg";
  #   };
  #
  # Dieser Host nutzt aktuell den Roh-String-Escape-Hatch `extraMonitorSettings`
  # (greift nur, solange `monitors` leer ist).
  # Hyprland Settings


  #  extraMonitorSettings = "
  #    monitor=DP-2,2560x1440@165,0x0,1
  #    monitor=HDMI-A-1,1920x1080@60,0x-1080,1
  #    monitor=DP-1,2560x1440@60,-1440x-1000, 1, transform,3
  #";

  monitors = [
     "DP-1,2560x1440@144,0x0,1"
     "HDMI-A-1,1920x1080@60,2560x0,1"
  ];
  
  wallpapers = {
     "eDP-1" = "Legend_of_Zelda.png";   # eingebautes MacBook-Panel
     "DP-1" = "Itachi.jpg";         # extern, nur im Dock
     "HDMI-A-1" = "grogu.jpg";
  };

  workspaceSettings = [
        "name:1, monitor:DP-2"
        "name:2, monitor:DP-1"
        "name:3, monitor:HDMI-A-1"
      ];


  guiActivation = true;


  # Waybar Settings
  clock24h = true;

  # Program Options
  browser = "firefox"; # Set Default Browser
  terminal = "kitty"; # Set Default System Terminal
  discordClient = "vesktop"; # Discord client (Apple Silicon)
  keyboardLayout = "de";
  consoleKeyMap = "de";

  # ---- Feature toggles (bridged into machineProfiles / customConf) ----
  profiles = {
    desktop = {
      enable = true;
      gaming.enable = false;
      communication.enable = true;
      flatpak.enable = true;
      audio.enable = true;
      printing.enable = true;
      bluetooth.enable = true;
      office.enable = true;
      desktopIntegration.enable = true;
      usbImaging.enable = true;
    };

    server = {
      enable = false;
      reverseProxy.enable = false;
      adguard.enable = false;
      media.enable = false;
      audiobookshelf.enable = false;
      homesuite.enable = false;
      sonarqube.enable = false;
      gitea.enable = false;
      dependencyTrack.enable = false;
      stepCa.enable = false;
      nfsServer.enable = false;
      serverBattery.enable = false;
    };

    network = {
      remoteAccess.enable = true;
      copyTools.enable = true;
      vpn.enable = true;
      networkDiscovery.enable = true;
    };

    security = {
      enable = false;
      pentest.enable = false;
      exploitDev.enable = false;
      reversing.enable = true;
      networkAnalysis.enable = false;
      remoteScan.enable = false;
    };

    apple = {
      allowUnsupported.enable = false;
      x86Emulation.enable = true;
      steam.enable = false;
      batteryPerformance.enable = false;
    };

    virtualization.enable = true;
    dev.dotnet.enable = false;
  };

  customConf = {
    nasMount.enable = true;
    fingerprint.enable = true;
  };
}
