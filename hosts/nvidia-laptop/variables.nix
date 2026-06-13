{
  gitUsername = "obliv0nisnice";
  gitEmail = "anrufen_nahm0p@icloud.com";

  extraMonitorSettings = "";
  workspaceSettings = [ ];
  guiActivation = true;

  clock24h = true;

  browser = "floorp";
  terminal = "kitty";
  keyboardLayout = "de";
  consoleKeyMap = "de";

  intelID = "PCI:1:0:0";
  nvidiaID = "PCI:0:2:0";

  # ---- Feature toggles (bridged into machineProfiles / customConf) ----
  profiles = {
    desktop = {
      enable = true;
      gaming.enable = true;
      communication.enable = true;
      flatpak.enable = true;
      audio.enable = true;
      printing.enable = true;
      bluetooth.enable = true;
      office.enable = false;
      desktopIntegration.enable = true;
      usbImaging.enable = false;
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
    nasMount.enable = false;
    fingerprint.enable = false;
  };
}
