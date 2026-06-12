{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.fingerprint;
in
{
  options.fingerprint = {
    enable = lib.mkEnableOption "Enables fingerprint sensor support";
  };

  config = lib.mkIf cfg.enable {

    services.fprintd = {
      enable = true;
    };
  };
}
