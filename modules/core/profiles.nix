{
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption;
in
{
  options.machineProfiles = {
    desktop.enable = mkEnableOption "desktop modules, GUI services and graphical home-manager setup" // {
      default = true;
    };

    server.enable = mkEnableOption "server-oriented behavior and service layout" // {
      default = false;
    };

    desktopIntegration.enable = mkEnableOption "desktop integration helpers such as gvfs and networkmanager applet" // {
      default = true;
    };

    remoteAccess.enable = mkEnableOption "remote access via SSH and related firewall openings" // {
      default = true;
    };

    copyTools.enable = mkEnableOption "copy/sync tools for SSH, SFTP, rsync and remote mounts" // {
      default = true;
    };

    virtualization.enable = mkEnableOption "docker, libvirt and virt-manager support" // {
      default = true;
    };

    gaming.enable = mkEnableOption "gaming stack such as Steam and 32-bit graphics support" // {
      default = true;
    };

    communication.enable = mkEnableOption "communication desktop apps" // {
      default = true;
    };

    flatpak.enable = mkEnableOption "flatpak support" // {
      default = true;
    };

    audio.enable = mkEnableOption "audio stack such as pipewire and rtkit" // {
      default = true;
    };

    printing.enable = mkEnableOption "printing and scanner desktop integration" // {
      default = true;
    };

    bluetooth.enable = mkEnableOption "bluetooth services and support" // {
      default = true;
    };

    security = {
      enable = mkEnableOption "the NixOS security toolbox profile" // {
        default = false;
      };
      pentest.enable = mkEnableOption "AD/service pentest tools (impacket, medusa, smtp-user-enum)";
      exploitDev.enable = mkEnableOption "exploit-dev & debugging tools (gdb, pwntools, boofuzz)";
      reversing.enable = mkEnableOption "reverse-engineering tools (unblob)";
      networkAnalysis.enable = mkEnableOption "network analysis tools (wireshark)";
      remoteScan.enable = mkEnableOption "remote scan/connect helpers (openvpn, openconnect, openscap, remmina)";
    };

    reverseProxy.enable = mkEnableOption "reverse proxy stack such as nginx and ACME" // {
      default = false;
    };

    adguard.enable = mkEnableOption "AdGuard Home DNS service" // {
      default = false;
    };

    media.enable = mkEnableOption "media services such as Jellyfin-related storage setup" // {
      default = false;
    };

    audiobookshelf.enable = mkEnableOption "audiobookshelf container" // {
      default = false;
    };

    homesuite.enable = mkEnableOption "HomeSuite backend service" // {
      default = false;
    };

    sonarqube.enable = mkEnableOption "SonarQube code quality service" // {
      default = false;
    };

    gitea.enable = mkEnableOption "Gitea self-hosted git service" // {
      default = false;
    };

    dependencyTrack.enable = mkEnableOption "Dependency Track SBOM and vulnerability analysis" // {
      default = false;
    };

    stepCa.enable = mkEnableOption "step-ca private ACME certificate authority" // {
      default = false;
    };

    nfsServer.enable = mkEnableOption "NFS server exports and rpcbind" // {
      default = false;
    };

    serverBattery.enable = mkEnableOption "battery-oriented server tuning" // {
      default = false;
    };

    # Apple-Silicon / Mac-oriented options (used by the macbook host).
    allowUnsupported.enable = mkEnableOption "allow unsupported packages (allowUnsupportedSystem) on Apple Silicon";
    x86Emulation.enable = mkEnableOption "x86_64 binfmt emulation on Apple Silicon";
    vpn.enable = mkEnableOption "VPN services (mullvad, netbird)" // {
      default = false;
    };
    dotnet.enable = mkEnableOption "the .NET 8 SDK";
    office.enable = mkEnableOption "office/productivity desktop packages (libreoffice, anki)";
    networkDiscovery.enable = mkEnableOption "mDNS/zeroconf network discovery" // {
      default = false;
    };
    usbImaging.enable = mkEnableOption "USB printer/scanner helper services" // {
      default = false;
    };
    batteryPerformance.enable = mkEnableOption "a lighter Hyprland profile for battery/performance testing";
  };
}
