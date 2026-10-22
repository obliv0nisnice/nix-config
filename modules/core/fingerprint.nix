{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.machineProfiles.desktop.fingerprint;
in
{
  config = lib.mkIf cfg.enable {

    services.fprintd = {
      enable = true;
    };
  };
}
