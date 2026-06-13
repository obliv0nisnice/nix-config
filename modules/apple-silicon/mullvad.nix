{
  config,
  lib,
  ...
}:

{
  config = lib.mkIf config.machineProfiles.network.vpn.enable {
    services.mullvad-vpn.enable = true;
  };
}
