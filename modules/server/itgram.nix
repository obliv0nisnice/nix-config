{
  config,
  pkgs,
  lib,
  username,
  ...
}:

let
  inherit (lib) mkIf mkOption types escapeShellArg makeBinPath;

  cfg = config.services.itgram;

  appUser = "itgram";
  appGroup = "itgram";

  appRoot = "/var/lib/itgram";
  workerRoot = "${appRoot}/worker";
  workerDll = "ITgram.Worker.dll";

  # Eigener Postgres-16-Container mit pgvector: die geteilte native Instanz
  # (homesuite) läuft per stateVersion 23.11 als Postgres 15 — ITgram braucht
  # laut Stack PG16 + pgvector, ohne homesuite ein pg_upgrade aufzuzwingen.
  dbContainer = "itgram-db";

  toolPath = makeBinPath [
    pkgs.bash
    pkgs.coreutils
    pkgs.findutils
    pkgs.gnugrep
    pkgs.gnused
    pkgs.git
    pkgs.rsync
    pkgs.systemd
    pkgs.dotnetCorePackages.sdk_9_0
  ];

  defaultConnectionString =
    "Host=127.0.0.1;Port=${toString cfg.database.port};Database=${cfg.database.name};Username=${cfg.database.user};Password=${cfg.database.password}";

  deployScript = pkgs.writeShellScriptBin "itgram-deploy" ''
    #!${pkgs.bash}/bin/bash
    set -Eeuo pipefail

    SRC_ROOT=${escapeShellArg cfg.sourceRoot}
    WORKER_PROJECT="$SRC_ROOT/src/ITgram.Worker/ITgram.Worker.csproj"

    TIMESTAMP="$(${pkgs.coreutils}/bin/date +%F_%H-%M-%S)"
    TMP_ROOT="$(${pkgs.coreutils}/bin/mktemp -d /tmp/itgram-deploy-XXXXXX)"
    WORKER_TMP="$TMP_ROOT/worker"
    WORKER_RELEASE="${workerRoot}/releases/$TIMESTAMP"

    export HOME="${appRoot}/.deploy-home"
    export PATH=${escapeShellArg toolPath}:$PATH
    trap '${pkgs.coreutils}/bin/rm -rf "$TMP_ROOT"' EXIT

    if [ ! -d "$SRC_ROOT" ]; then
      echo "ITgram source root fehlt: $SRC_ROOT" >&2
      exit 1
    fi

    # Checkout ist (noch) nicht zwingend ein Git-Repo — pull nur wenn vorhanden.
    if [ -d "$SRC_ROOT/.git" ]; then
      echo "==> Quellcode aktualisieren (git pull)"
      ${pkgs.util-linux}/bin/runuser -u ${username} -- \
        ${pkgs.coreutils}/bin/env HOME=/home/${username} GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh -o BatchMode=yes" \
        ${pkgs.git}/bin/git -C "$SRC_ROOT" pull --ff-only
    fi

    if [ ! -f "$WORKER_PROJECT" ]; then
      echo "Worker project fehlt: $WORKER_PROJECT" >&2
      exit 1
    fi

    ${pkgs.coreutils}/bin/mkdir -p "$WORKER_TMP"
    ${pkgs.coreutils}/bin/chown -R ${username}: "$TMP_ROOT"

    # Build als Checkout-Besitzer, damit bin/obj im Checkout nicht root gehören.
    echo "==> Worker bauen"
    ${pkgs.util-linux}/bin/runuser -u ${username} -- \
      ${pkgs.coreutils}/bin/env HOME=/home/${username} \
      ${pkgs.dotnetCorePackages.sdk_9_0}/bin/dotnet publish "$WORKER_PROJECT" -c Release -o "$WORKER_TMP"

    if [ ! -f "$WORKER_TMP/${workerDll}" ]; then
      echo "Worker-Artefakt fehlt: ${workerDll}" >&2
      exit 1
    fi

    echo "==> Release anlegen und umstellen"
    ${pkgs.coreutils}/bin/mkdir -p "$WORKER_RELEASE"
    ${pkgs.rsync}/bin/rsync -av --delete "$WORKER_TMP/" "$WORKER_RELEASE/"
    ${pkgs.coreutils}/bin/ln -sfn "$WORKER_RELEASE" "${workerRoot}/current"
    ${pkgs.coreutils}/bin/chown -R ${appUser}:${appGroup} "${appRoot}"

    echo "==> Migrationen anwenden"
    ${pkgs.systemd}/bin/systemctl start itgram-migrate.service

    echo "==> Worker neu starten"
    ${pkgs.systemd}/bin/systemctl restart itgram-worker.service

    # Konsolen-Worker ohne HTTP-Endpoint: Health = Unit läuft nach kurzer Frist noch.
    ${pkgs.coreutils}/bin/sleep 5
    if ! ${pkgs.systemd}/bin/systemctl is-active --quiet itgram-worker.service; then
      echo "itgram-worker läuft nach dem Deploy nicht." >&2
      ${pkgs.systemd}/bin/systemctl status itgram-worker.service --no-pager >&2 || true
      exit 1
    fi
    echo "Worker läuft."

    echo "==> Alte Releases aufräumen (die letzten 5 bleiben)"
    ${pkgs.coreutils}/bin/ls -1 "${workerRoot}/releases" | ${pkgs.coreutils}/bin/sort | ${pkgs.coreutils}/bin/head -n -5 | while IFS= read -r OLD_RELEASE; do
      ${pkgs.coreutils}/bin/rm -rf "${workerRoot}/releases/$OLD_RELEASE"
    done
  '';

  migrateScript = pkgs.writeShellScriptBin "itgram-migrate" ''
    #!${pkgs.bash}/bin/bash
    set -Eeuo pipefail

    SRC_ROOT=${escapeShellArg cfg.sourceRoot}
    INFRA_PROJECT="$SRC_ROOT/src/ITgram.Infrastructure/ITgram.Infrastructure.csproj"

    export HOME="${appRoot}/.deploy-home"
    export PATH=${escapeShellArg toolPath}:$PATH

    # EnvironmentFile liefert systemd; Default nur als Fallback (localhost-only).
    if [ -z "''${ConnectionStrings__DefaultConnection:-}" ]; then
      export ConnectionStrings__DefaultConnection=${escapeShellArg defaultConnectionString}
    fi

    if [ ! -f "$INFRA_PROJECT" ]; then
      echo "Infrastructure project fehlt: $INFRA_PROJECT" >&2
      exit 1
    fi

    cd "$SRC_ROOT"
    # dotnet-ef kommt gepinnt aus dem Tool-Manifest des Repos (.config/dotnet-tools.json),
    # damit Tool- und EF-Version zusammenpassen.
    ${pkgs.dotnetCorePackages.sdk_9_0}/bin/dotnet tool restore
    ${pkgs.dotnetCorePackages.sdk_9_0}/bin/dotnet ef database update \
      --project "$INFRA_PROJECT" \
      --startup-project "$INFRA_PROJECT"
  '';
in
{
  options.services.itgram = {
    sourceRoot = mkOption {
      type = types.str;
      default = "/home/${username}/ITgram";
      description = "Local ITgram checkout used by the deploy and migration commands.";
    };

    environmentFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Optional environment file for worker and migration (real secrets, z. B.
        `ConnectionStrings__DefaultConnection`, NVD-API-Key). Überschreibt den
        Default-Connection-String aus dem (world-readable) nix store.
      '';
    };

    database = {
      name = mkOption {
        type = types.str;
        default = "itgram";
        description = "PostgreSQL database name inside the itgram-db container.";
      };

      user = mkOption {
        type = types.str;
        default = "itgram";
        description = "PostgreSQL user inside the itgram-db container.";
      };

      password = mkOption {
        type = types.str;
        default = "itgram";
        description = ''
          PostgreSQL password. WARNING: landet world-readable im nix store —
          für den localhost-only Container akzeptabel, sonst environmentFile nutzen.
        '';
      };

      port = mkOption {
        type = types.port;
        default = 5433;
        description = "Host port for the itgram-db container (5432 belegt die native Instanz).";
      };
    };
  };

  config = mkIf config.machineProfiles.server.itgram.enable {
    users.groups.${appGroup} = {};

    users.users.${appUser} = {
      isSystemUser = true;
      group = appGroup;
      home = "/var/empty";
      createHome = false;
      description = "ITgram service user";
    };

    environment.systemPackages = [
      deployScript
      migrateScript
    ];

    virtualisation.docker.enable = true;
    virtualisation.oci-containers.backend = "docker";

    virtualisation.oci-containers.containers.${dbContainer} = {
      # Offizielles pgvector-Image auf Postgres-16-Basis
      image = "pgvector/pgvector:pg16";
      ports = [ "127.0.0.1:${toString cfg.database.port}:5432" ];
      environment = {
        POSTGRES_DB = cfg.database.name;
        POSTGRES_USER = cfg.database.user;
        POSTGRES_PASSWORD = cfg.database.password;
      };
      volumes = [
        "${appRoot}/postgresql:/var/lib/postgresql/data"
      ];
    };

    systemd.tmpfiles.rules = [
      "d ${appRoot} 0755 ${appUser} ${appGroup} - -"
      "d ${appRoot}/.deploy-home 0755 root root - -"
      "d ${appRoot}/postgresql 0700 999 999 - -"
      "d ${workerRoot} 0755 ${appUser} ${appGroup} - -"
      "d ${workerRoot}/releases 0755 ${appUser} ${appGroup} - -"
      # Frontend-Root für den nginx-vhost itgram.nestlerlabs.at (SPA kommt in Phase 2)
      "d ${appRoot}/frontend 0755 ${appUser} ${appGroup} - -"
      "d ${appRoot}/frontend/releases 0755 ${appUser} ${appGroup} - -"
    ];

    systemd.services.itgram-worker = {
      description = "ITgram content pipeline worker";
      after = [ "network-online.target" "docker-${dbContainer}.service" ];
      wants = [ "network-online.target" "docker-${dbContainer}.service" ];
      wantedBy = [ "multi-user.target" ];

      # Vor dem ersten `itgram-deploy` gibt es noch kein current-Release; ohne
      # diese Bedingung würde die Unit bei jeder Aktivierung mit CHDIR (200)
      # failen und den nixos-rebuild rot einfärben. systemd überspringt die Unit
      # solange still — der Deploy startet sie danach per systemctl restart.
      unitConfig.ConditionPathExists = "${workerRoot}/current/${workerDll}";

      serviceConfig =
        {
          Type = "simple";
          User = appUser;
          Group = appGroup;
          WorkingDirectory = "${workerRoot}/current";
          ExecStart = "${pkgs.dotnetCorePackages.runtime_9_0}/bin/dotnet ${workerRoot}/current/${workerDll}";
          Restart = "always";
          RestartSec = "5s";
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ReadWritePaths = [ appRoot ];
        }
        // lib.optionalAttrs (cfg.environmentFile != null) {
          EnvironmentFile = cfg.environmentFile;
        };
      environment = {
        DOTNET_ENVIRONMENT = "Production";
        ConnectionStrings__DefaultConnection = defaultConnectionString;
      };
    };

    systemd.services.itgram-deploy = {
      description = "Build and deploy the ITgram worker";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        Type = "oneshot";
        User = "root";
        Group = "root";
        ExecStart = "${deployScript}/bin/itgram-deploy";
      };
    };

    systemd.services.itgram-migrate = {
      description = "Run ITgram Entity Framework migrations";
      after = [ "network-online.target" "docker-${dbContainer}.service" ];
      wants = [ "network-online.target" "docker-${dbContainer}.service" ];

      serviceConfig =
        {
          Type = "oneshot";
          User = "root";
          Group = "root";
          ExecStart = "${migrateScript}/bin/itgram-migrate";
        }
        // lib.optionalAttrs (cfg.environmentFile != null) {
          EnvironmentFile = cfg.environmentFile;
        };
    };
  };
}
