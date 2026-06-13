{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.machineProfiles.server.stepCa;
  intermediatePasswordPath =
    if (config.sops.secrets or {}) ? "step-ca/intermediate-password"
    then config.sops.secrets."step-ca/intermediate-password".path
    else "/var/lib/step-ca/secrets/intermediate-password";
in
{
  options.machineProfiles.server.stepCa = {
    domain = lib.mkOption {
      type = lib.types.str;
      default = "ca.nestlerlabs.at";
      description = "DNS name the step-ca instance answers on.";
    };

    listenPort = lib.mkOption {
      type = lib.types.port;
      default = 8443;
      description = "TCP port step-ca listens on (TLS terminated by step-ca itself).";
    };
  };

  config = lib.mkIf cfg.enable {
    services.step-ca = {
      enable = true;
      address = "0.0.0.0";
      port = cfg.listenPort;
      openFirewall = true;
      intermediatePasswordFile = intermediatePasswordPath;
      settings = {
        root = "/var/lib/step-ca/certs/root_ca.crt";
        federatedRoots = [];
        crt = "/var/lib/step-ca/certs/intermediate_ca.crt";
        key = "/var/lib/step-ca/secrets/intermediate_ca_key";
        dnsNames = [
          cfg.domain
          "127.0.0.1"
          "localhost"
        ];
        logger.format = "text";
        db = {
          type = "badgerv2";
          dataSource = "/var/lib/step-ca/db";
        };
        authority = {
          provisioners = [
            {
              type = "ACME";
              name = "acme";
              forceCN = true;
            }
          ];
        };
        tls = {
          minVersion = 1.2;
          maxVersion = 1.3;
          renegotiation = false;
        };
      };
    };

    environment.systemPackages = with pkgs; [ step-cli step-ca ];

    systemd.tmpfiles.rules = [
      "d /var/lib/step-ca 0750 step-ca step-ca - -"
      "d /var/lib/step-ca/certs 0755 step-ca step-ca - -"
      "d /var/lib/step-ca/secrets 0700 step-ca step-ca - -"
      "d /var/lib/step-ca/db 0700 step-ca step-ca - -"
    ];
  };
}
