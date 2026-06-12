{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
  ];

  machineProfiles = {
    server.enable = true;
    desktop.enable = false;
    desktopIntegration.enable = false;
    remoteAccess.enable = true;
    copyTools.enable = true;
    virtualization.enable = true;
    gaming.enable = false;
    communication.enable = false;
    flatpak.enable = false;
    audio.enable = false;
    printing.enable = false;
    bluetooth.enable = false;
    security.enable = false;
    reverseProxy.enable = true;
    adguard.enable = true;
    media.enable = true;
    audiobookshelf.enable = true;
    homesuite.enable = true;
    sonarqube.enable = true;
    nfsServer.enable = false;
    serverBattery.enable = false;
    gitea.enable = true;
    dependencyTrack.enable = true;
    stepCa.enable = true;
  };

  NixOS-Sec-Toolbox.enable = false;
  netbird-client.enable = true;

  NASMount.enable = true;
}
