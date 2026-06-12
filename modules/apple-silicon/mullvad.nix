{
  config,
  lib,
  ...
}:

{
  config = lib.mkIf config.machineProfiles.vpn.enable {
    services.mullvad-vpn.enable = true;
  };
}
