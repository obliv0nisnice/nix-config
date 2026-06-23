{
  # Git Configuration ( For Pulling Software Repos )
  gitUsername = "obliv0nisnice";
  gitEmail = "anrufen_nahm0p@icloud.com";

  # Hyprland Settings
  extraMonitorSettings = "";
  

  workspaceSettings = [
    #    "name:1, monitor:DP-2"
    #    "name:2, monitor:DP-1"
    #    "name:3, monitor:HDMI-A-1"
      ];

  guiActivation = false;

  # Waybar Settings
  clock24h = true;

  # Program Options
  browser = "floorp"; # Set Default Browser
  terminal = "kitty"; # Set Default System Terminal
  discordClient = "discord";
  keyboardLayout = "de";
  consoleKeyMap = "de";

  # intelID = "PCI:1:0:0";
  # nvidiaID = "PCI:0:2:0";

  # ---- Feature toggles (bridged into machineProfiles / customConf) ----
  profiles = {
    desktop = {
      enable = false;
      gaming.enable = false;
      communication.enable = false;
      flatpak.enable = false;
      audio.enable = false;
      printing.enable = false;
      bluetooth.enable = false;
      office.enable = false;
      desktopIntegration.enable = false;
      usbImaging.enable = false;
    };

    server = {
      enable = true;
      reverseProxy.enable = true;
      adguard.enable = true;
      media.enable = true;
      audiobookshelf.enable = true;
      homesuite.enable = true;
      sonarqube.enable = true;
      gitea.enable = true;
      dependencyTrack.enable = true;
      stepCa.enable = true;
      nfsServer.enable = false;
      serverBattery.enable = false;
    };

    network = {
      remoteAccess.enable = true;
      copyTools.enable = true;
      vpn.enable = false;
      networkDiscovery.enable = false;
    };

    security = {
      enable = false;
      pentest.enable = false;
      exploitDev.enable = false;
      reversing.enable = false;
      networkAnalysis.enable = false;
      remoteScan.enable = false;
    };

    apple = {
      allowUnsupported.enable = false;
      x86Emulation.enable = false;
      batteryPerformance.enable = false;
    };

    virtualization.enable = true;
    dev.dotnet.enable = false;
  };

  customConf = {
    nasMount.enable = true;
    fingerprint.enable = false;
    netbird.enable = true;
  };
}
