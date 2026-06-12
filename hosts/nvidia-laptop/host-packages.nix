{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [ ];

  machineProfiles = {
    server.enable = false;
    desktop.enable = true;
    desktopIntegration.enable = true;
    remoteAccess.enable = true;
    copyTools.enable = true;
    virtualization.enable = true;
    gaming.enable = true;
    communication.enable = true;
    flatpak.enable = true;
    audio.enable = true;
    printing.enable = true;
    bluetooth.enable = true;
    security.enable = false;
    reverseProxy.enable = false;
    adguard.enable = false;
    media.enable = false;
    homesuite.enable = false;
    nfsServer.enable = false;
    serverBattery.enable = false;
  };

  NixOS-Sec-Toolbox.enable = false;
  NASMount.enable = false;
  fingerprint.enable = false;
}
