{
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption;
  onByDefault = desc: mkEnableOption desc // { default = true; };
in
{
  options.machineProfiles = {
    desktop = {
      enable = onByDefault "desktop modules, GUI services and graphical home-manager setup";
      gaming.enable = onByDefault "gaming stack such as Steam and 32-bit graphics support";
      communication.enable = onByDefault "communication desktop apps";
      flatpak.enable = onByDefault "flatpak support";
      audio.enable = onByDefault "audio stack such as pipewire and rtkit";
      printing.enable = onByDefault "printing and scanner desktop integration";
      bluetooth.enable = onByDefault "bluetooth services and support";
      office.enable = mkEnableOption "office/productivity desktop packages (libreoffice, anki)";
      desktopIntegration.enable = onByDefault "desktop integration helpers such as gvfs and networkmanager applet";
      usbImaging.enable = mkEnableOption "USB printer/scanner helper services";
    };

    server = {
      enable = mkEnableOption "server-oriented behavior and service layout";
      reverseProxy.enable = mkEnableOption "reverse proxy stack such as nginx and ACME";
      adguard.enable = mkEnableOption "AdGuard Home DNS service";
      media.enable = mkEnableOption "media services such as Jellyfin-related storage setup";
      audiobookshelf.enable = mkEnableOption "audiobookshelf container";
      homesuite.enable = mkEnableOption "HomeSuite backend service";
      sonarqube.enable = mkEnableOption "SonarQube code quality service";
      gitea.enable = mkEnableOption "Gitea self-hosted git service";
      dependencyTrack.enable = mkEnableOption "Dependency Track SBOM and vulnerability analysis";
      stepCa.enable = mkEnableOption "step-ca private ACME certificate authority";
      nfsServer.enable = mkEnableOption "NFS server exports and rpcbind";
      serverBattery.enable = mkEnableOption "battery-oriented server tuning";
    };

    network = {
      remoteAccess.enable = onByDefault "remote access via SSH and related firewall openings";
      copyTools.enable = onByDefault "copy/sync tools for SSH, SFTP, rsync and remote mounts";
      vpn.enable = mkEnableOption "VPN services (mullvad, netbird)";
      networkDiscovery.enable = mkEnableOption "mDNS/zeroconf network discovery";
    };

    security = {
      enable = mkEnableOption "the NixOS security toolbox profile";
      pentest.enable = mkEnableOption "AD/service pentest tools (impacket, medusa, smtp-user-enum)";
      exploitDev.enable = mkEnableOption "exploit-dev & debugging tools (gdb, pwntools, boofuzz)";
      reversing.enable = mkEnableOption "reverse-engineering tools (unblob)";
      networkAnalysis.enable = mkEnableOption "network analysis tools (wireshark)";
      remoteScan.enable = mkEnableOption "remote scan/connect helpers (openvpn, openconnect, openscap, remmina)";
    };

    apple = {
      allowUnsupported.enable = mkEnableOption "allow unsupported packages (allowUnsupportedSystem) on Apple Silicon";
      x86Emulation.enable = mkEnableOption "x86_64 binfmt emulation on Apple Silicon";
      batteryPerformance.enable = mkEnableOption "a lighter Hyprland profile for battery/performance testing";
    };

    virtualization.enable = onByDefault "docker, libvirt and virt-manager support";
    dev.dotnet.enable = mkEnableOption "the .NET 8 SDK";
  };
}
