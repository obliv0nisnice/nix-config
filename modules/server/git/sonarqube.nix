{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.machineProfiles.server.sonarqube;
  dataRoot = "/var/lib/sonarqube";
  networkName = "sonarqube-net";
  hasSopsEnv = builtins.pathExists ../../../secrets/secrets.yaml;
  sopsEnvFile = lib.optional hasSopsEnv "/run/secrets/sonarqube/env";
in
{
  config = lib.mkIf cfg.enable {
    virtualisation.docker.enable = true;
    virtualisation.oci-containers.backend = "docker";

    boot.kernel.sysctl."fs.file-max" = lib.mkDefault 131072;

    systemd.tmpfiles.rules = [
      "d ${dataRoot} 0755 root root - -"
      "d ${dataRoot}/postgresql 0700 999 999 - -"
      "d ${dataRoot}/data 0755 1000 1000 - -"
      "d ${dataRoot}/extensions 0755 1000 1000 - -"
      "d ${dataRoot}/logs 0755 1000 1000 - -"
      "d ${dataRoot}/temp 0755 1000 1000 - -"
    ];

    systemd.services.docker-sonarqube-network = {
      path = [pkgs.docker];
      description = "Create sonarqube Docker network";
      before = [
        "docker-sonarqube-db.service"
        "docker-sonarqube.service"
      ];
      wantedBy = [
        "docker-sonarqube-db.service"
        "docker-sonarqube.service"
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
      sonarqube-db = {
        image = "postgres:16";
        environment = {
          POSTGRES_USER = "sonarqube";
          POSTGRES_DB = "sonarqube";
        } // lib.optionalAttrs (!hasSopsEnv) {
          POSTGRES_PASSWORD = "sonarqube";
        };
        environmentFiles = sopsEnvFile;
        volumes = [
          "${dataRoot}/postgresql:/var/lib/postgresql/data"
        ];
        extraOptions = [ "--network=${networkName}" ];
      };

      sonarqube = {
        image = "sonarqube:community";
        ports = [ "127.0.0.1:9000:9000" ];
        environment = {
          SONAR_JDBC_URL = "jdbc:postgresql://sonarqube-db:5432/sonarqube";
          SONAR_JDBC_USERNAME = "sonarqube";
        } // lib.optionalAttrs (!hasSopsEnv) {
          SONAR_JDBC_PASSWORD = "sonarqube";
        };
        environmentFiles = sopsEnvFile;
        volumes = [
          "${dataRoot}/data:/opt/sonarqube/data"
          "${dataRoot}/extensions:/opt/sonarqube/extensions"
          "${dataRoot}/logs:/opt/sonarqube/logs"
          "${dataRoot}/temp:/opt/sonarqube/temp"
        ];
        dependsOn = [ "sonarqube-db" ];
        extraOptions = [ "--network=${networkName}" ];
      };
    };

    systemd.services.docker-sonarqube = {
      after = [ "docker-sonarqube-db.service" "docker-sonarqube-network.service" ];
      requires = [ "docker-sonarqube-db.service" ];
      serviceConfig = {
        LimitNOFILE = 131072;
        LimitNPROC = 8192;
      };
    };
  };
}

