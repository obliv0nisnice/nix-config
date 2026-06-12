{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [ ];

  machineProfiles = {
    desktop.enable = true;
    server.enable = false;

    # x86-only stacks stay off on Apple Silicon.
    gaming.enable = false;

    virtualization.enable = true;
    desktopIntegration.enable = true;
    remoteAccess.enable = true;
    copyTools.enable = true;
    communication.enable = true;
    flatpak.enable = true;
    audio.enable = true;
    printing.enable = true;
    bluetooth.enable = true;
    office.enable = true;

    # Apple-Silicon specifics.
    allowUnsupported.enable = false;
    x86Emulation.enable = true;
    vpn.enable = true;
    networkDiscovery.enable = true;
    usbImaging.enable = true;
    batteryPerformance.enable = false;
    dotnet.enable = false;

    security = {
      enable = false;
      pentest.enable = false;
      exploitDev.enable = false;
      reversing.enable = false;
      networkAnalysis.enable = false;
      remoteScan.enable = false;
    };
  };

  NixOS-Sec-Toolbox.enable = config.machineProfiles.security.enable;
  NASMount.enable = true;
  fingerprint.enable = true;

  programs.qylock.lockTheme = "pixel-hollowknight";
}
