{
  config,
  lib,
  ...
}:

{
  config = lib.mkIf config.machineProfiles.network.vpn.enable {
    services.netbird.clients.wt0 = {
      login = {
        enable = false;
        setupKeyFile = "/path/to/your/setup-key";
      };
      port = 51821;
      ui.enable = false;
      openFirewall = true;
      openInternalFirewall = true;
    
    };
  };
}
