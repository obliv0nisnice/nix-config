{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.machineProfiles.dependencyTrack;
  dataRoot = "/var/lib/dependency-track";
  networkName = "dtrack-net";
  hasSopsEnv = builtins.pathExists ../../../secrets/secrets.yaml;
  sopsEnvFile = lib.optional hasSopsEnv "/run/secrets/dependency-track/env";
in
{
  config = lib.mkIf cfg.enable {
    virtualisation.docker.enable = true;
    virtualisation.oci-containers.backend = "docker";

    systemd.tmpfiles.rules = [
      "d ${dataRoot} 0755 root root - -"
      "d ${dataRoot}/data 0755 1000 1000 - -"
      "d ${dataRoot}/postgresql 0700 999 999 - -"
    ];

    # Netzwerk vor den Containern anlegen
    systemd.services.docker-dtrack-network = {
      path = [pkgs.docker];
      description = "Create dtrack Docker network";
      before = [
        "docker-dependency-track-db.service"
        "docker-dependency-track-apiserver.service"
        "docker-dependency-track-frontend.service"
      ];
      wantedBy = [
        "docker-dependency-track-db.service"
        "docker-dependency-track-apiserver.service"
        "docker-dependency-track-frontend.service"
      ];
      after = [ "docker.service" ];
      requires = [ "docker.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "/bin/sh -c 'docker network inspect ${networkName} > /dev/null 2>&1 || docker network create ${networkName}'";
        ExecStop = "/bin/sh -c 'docker network rm ${networkName} || true'";
      };
    };

    virtualisation.oci-containers.containers = {

      dependency-track-db = {
        image = "postgres:16";
        environment = {
          POSTGRES_USER = "dtrack";
          POSTGRES_DB = "dtrack";
        } // lib.optionalAttrs (!hasSopsEnv) {
          POSTGRES_PASSWORD = "dtrack";
        };
        environmentFiles = sopsEnvFile;
        volumes = [
          "${dataRoot}/postgresql:/var/lib/postgresql/data"
        ];
        extraOptions = [ "--network=${networkName}" ];
      };

      dependency-track-apiserver = {
        image = "dependencytrack/apiserver:latest";
        ports = [ "127.0.0.1:8081:8080" ];
        environment = {
          ALPINE_DATABASE_MODE = "external";
          ALPINE_DATABASE_URL = "jdbc:postgresql://dependency-track-db:5432/dtrack";
          ALPINE_DATABASE_DRIVER = "org.postgresql.Driver";
          ALPINE_DATABASE_USERNAME = "dtrack";
        } // lib.optionalAttrs (!hasSopsEnv) {
          ALPINE_DATABASE_PASSWORD = "dtrack";
        };
        environmentFiles = sopsEnvFile;
        volumes = [
          "${dataRoot}/data:/data"
        ];
        dependsOn = [ "dependency-track-db" ];
        extraOptions = [
          "--network=${networkName}"
          "--memory=4096m"
          "--memory-reservation=2048m"
        ];
      };

      dependency-track-frontend = {
        image = "dependencytrack/frontend:latest";
        ports = [ "127.0.0.1:8082:8080" ];
        environment = {
          API_BASE_URL = "https://dtrack.nestlerlabs.at";
        };
        dependsOn = [ "dependency-track-apiserver" ];
        extraOptions = [ "--network=${networkName}" ];
      };
    };
  };
}

