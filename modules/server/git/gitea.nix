{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.machineProfiles.gitea;
  dataRoot = "/var/lib/gitea";
in
{
  config = lib.mkIf cfg.enable {
    services.gitea = {
      enable = true;
      appName = "Nestler Labs Gitea";
      stateDir = dataRoot;

      database = {
        type = "postgres";
        host = "127.0.0.1";
        port = 5432;
        name = "gitea";
        user = "gitea";
        passwordFile = "/etc/gitea/db-password";
      };

      settings = {
        server = {
          HTTP_ADDR = "127.0.0.1";
          HTTP_PORT = 3000;
          ROOT_URL = "https://gitea.nestlerlabs.at";
          DOMAIN = "gitea.nestlerlabs.at";
        };

        service = {
          DISABLE_REGISTRATION = false;
          REQUIRE_SIGNIN_VIEW = false;
        };

        actions = {
          ENABLED = true;
          DEFAULT_ACTIONS_URL = "https://gitea.nestlerlabs.at";
        };

        webhook = {
          ALLOWED_HOST_LIST = "127.0.0.1,localhost";
        };
      };
    };

    services.gitea-actions-runner.instances."local" = {
      enable = true;
      name = "nestlerlabs-runner";
      url = "https://gitea.nestlerlabs.at";
      tokenFile = "/etc/gitea/runner-token";

      labels = [
        "ubuntu-latest:docker://node:20-bullseye"
        "nix:docker://nixos/nix"
      ];

      settings = {
        runner.capacity = 4;
        container.valid_volumes = [ "/etc/ssl/step-ca-root.crt" ];
        container.options = lib.concatStringsSep " " [
          "-v /etc/ssl/step-ca-root.crt:/etc/ssl/certs/step-ca-root.crt:ro"
          "-e GIT_SSL_CAINFO=/etc/ssl/certs/step-ca-root.crt"
          "-e NODE_EXTRA_CA_CERTS=/etc/ssl/certs/step-ca-root.crt"
          "-e SSL_CERT_FILE=/etc/ssl/certs/step-ca-root.crt"
        ];
      };
    };

    # PostgreSQL-Datenbank für Gitea
    services.postgresql = {
      enable = true;
      ensureDatabases = [ "gitea" ];
      ensureUsers = [
        {
          name = "gitea";
          ensureClauses = {
            login = true;
          };
        }
      ];
    };

    systemd.tmpfiles.rules = [
      "d ${dataRoot} 0750 gitea gitea - -"
      "d /etc/gitea 0750 root root - -"
    ];
  };
}
