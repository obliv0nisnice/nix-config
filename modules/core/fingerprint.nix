{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.customConf.fingerprint;
in
{
  options.customConf.fingerprint = {
    enable = lib.mkEnableOption "Enables fingerprint sensor support";
  };

  config = lib.mkIf cfg.enable {

    services.fprintd = {
      enable = true;
    };
  };
}
