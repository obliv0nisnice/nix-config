{
  config,
  pkgs,
  host,
  options,
  lib,
  ...
}:
{
  networking = {
    hostName = "${host}";
    networkmanager.enable = true;
    networkmanager.plugins = lib.mkForce (lib.optionals config.machineProfiles.remoteAccess.enable [ pkgs.networkmanager-openvpn ]);
    timeServers = options.networking.timeServers.default ++ [ "pool.ntp.org" ];
    firewall = {
      enable = true;
      allowedTCPPorts = lib.optionals config.machineProfiles.remoteAccess.enable [
        22
      ] ++ lib.optionals config.machineProfiles.adguard.enable [
        53
      ] ++ lib.optionals config.machineProfiles.reverseProxy.enable [
        80
        443
      ] ++ lib.optionals config.machineProfiles.desktop.enable [
        59010
        59011
      ];
      allowedUDPPorts = lib.optionals config.machineProfiles.adguard.enable [
        53
      ] ++ lib.optionals config.machineProfiles.desktop.enable [
        59010
        59011
        4444
      ];
    };
  };

  environment.systemPackages = with pkgs; lib.optionals config.machineProfiles.desktopIntegration.enable [ networkmanagerapplet ];
}
