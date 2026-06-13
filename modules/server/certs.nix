{ config, lib, pkgs, ... }:

{
  config = lib.mkIf config.machineProfiles.server.reverseProxy.enable {
    security.pki.certificateFiles = [
      ./certs/nestlerlabs.crt
      ./certs/step-ca-root.crt
    ];

    environment.etc."ssl/nestlerlabs.crt".source = ./certs/nestlerlabs.crt;
    environment.etc."ssl/step-ca-root.crt".source = ./certs/step-ca-root.crt;
  };
}
