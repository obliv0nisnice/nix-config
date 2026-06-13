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
    networkmanager.plugins = lib.mkForce (lib.optionals config.machineProfiles.network.remoteAccess.enable [ pkgs.networkmanager-openvpn ]);
    timeServers = options.networking.timeServers.default ++ [ "pool.ntp.org" ];
    firewall = {
      enable = true;
      allowedTCPPorts = lib.optionals config.machineProfiles.network.remoteAccess.enable [
        22
      ] ++ lib.optionals config.machineProfiles.server.adguard.enable [
        53
      ] ++ lib.optionals config.machineProfiles.server.reverseProxy.enable [
        80
        443
      ] ++ lib.optionals config.machineProfiles.desktop.enable [
        59010
        59011
      ];
      allowedUDPPorts = lib.optionals config.machineProfiles.server.adguard.enable [
        53
      ] ++ lib.optionals config.machineProfiles.desktop.enable [
        59010
        59011
        4444
      ];
    };
  };

  environment.systemPackages = with pkgs; lib.optionals config.machineProfiles.desktop.desktopIntegration.enable [ networkmanagerapplet ];
}
