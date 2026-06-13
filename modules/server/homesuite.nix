{
  config,
  pkgs,
  lib,
  username,
  ...
}:

let
  inherit (lib) mkIf mkOption types escapeShellArg makeBinPath;

  cfg = config.services.homesuite;

  appUser = "homesuite";
  appGroup = "homesuite";

  appRoot = "/var/lib/homesuite";
  backendRoot = "${appRoot}/backend";
  frontendRoot = "${appRoot}/frontend";
  backendDll = "HomeSuite.API.dll";
  environmentFilePath = if cfg.environmentFile == null then "" else cfg.environmentFile;
  toolPath = makeBinPath [
    pkgs.bash
    pkgs.coreutils
    pkgs.curl
    pkgs.findutils
    pkgs.gawk
    pkgs.gnugrep
    pkgs.gnused
    pkgs.git
    pkgs.nodejs
    pkgs.rsync
    pkgs.systemd
    pkgs.dotnetCorePackages.sdk_8_0
    pkgs.dotnet-ef
  ];
  defaultConnectionString =
    "Host=127.0.0.1;Port=${toString cfg.database.port};Database=${cfg.database.name};Username=${cfg.database.user};Password=${cfg.database.password}";

  deployScript = pkgs.writeShellScriptBin "homesuite-deploy" ''
    #!${pkgs.bash}/bin/bash
    set -Eeuo pipefail

    SRC_ROOT=${escapeShellArg cfg.sourceRoot}
    BACKEND_SRC="$SRC_ROOT/backend/src/HomeSuite.API"
    BACKEND_PROJECT="$BACKEND_SRC/HomeSuite.API.csproj"
    FRONTEND_SRC="$SRC_ROOT/frontend"

    TIMESTAMP="$(${pkgs.coreutils}/bin/date +%F_%H-%M-%S)"
    TMP_ROOT="$(${pkgs.coreutils}/bin/mktemp -d /tmp/homesuite-deploy-XXXXXX)"
    BACKEND_TMP="$TMP_ROOT/backend"
    FRONTEND_TMP="$TMP_ROOT/frontend"

    BACKEND_RELEASE="${backendRoot}/releases/$TIMESTAMP"
    FRONTEND_RELEASE="${frontendRoot}/releases/$TIMESTAMP"

    export HOME="${appRoot}/.deploy-home"
    export PATH=${escapeShellArg toolPath}:$PATH
    trap '${pkgs.coreutils}/bin/rm -rf "$TMP_ROOT"' EXIT

    if [ ! -d "$SRC_ROOT" ]; then
      echo "HomeSuite source root fehlt: $SRC_ROOT" >&2
      exit 1
    fi

    if [ ! -f "$BACKEND_PROJECT" ]; then
      echo "Backend project fehlt: $BACKEND_PROJECT" >&2
      exit 1
    fi

    if [ ! -f "$FRONTEND_SRC/package.json" ]; then
      echo "Frontend package.json fehlt: $FRONTEND_SRC/package.json" >&2
      exit 1
    fi

    ${pkgs.coreutils}/bin/mkdir -p "$BACKEND_TMP" "$FRONTEND_TMP"

    echo "==> Backend bauen"
    cd "$BACKEND_SRC"
    ${pkgs.dotnetCorePackages.sdk_8_0}/bin/dotnet publish "$BACKEND_PROJECT" -c Release -o "$BACKEND_TMP"

    if [ ! -f "$BACKEND_TMP/${backendDll}" ]; then
      echo "Backend-Artefakt fehlt: ${backendDll}" >&2
      exit 1
    fi

    echo "==> Frontend bauen"
    cd "$FRONTEND_SRC"
    ${pkgs.nodejs}/bin/npm ci
    ${pkgs.nodejs}/bin/npm run build
    ${pkgs.rsync}/bin/rsync -av dist/ "$FRONTEND_TMP/"

    if [ ! -f "$FRONTEND_TMP/index.html" ]; then
      echo "Frontend-Artefakt fehlt: index.html" >&2
      exit 1
    fi

    echo "==> Release-Verzeichnisse anlegen"
    ${pkgs.coreutils}/bin/mkdir -p "$BACKEND_RELEASE" "$FRONTEND_RELEASE"

    echo "==> Artefakte kopieren"
    ${pkgs.rsync}/bin/rsync -av --delete "$BACKEND_TMP/" "$BACKEND_RELEASE/"
    ${pkgs.rsync}/bin/rsync -av --delete "$FRONTEND_TMP/" "$FRONTEND_RELEASE/"

    echo "==> Symlinks umstellen"
    ${pkgs.coreutils}/bin/ln -sfn "$BACKEND_RELEASE" "${backendRoot}/current"
    ${pkgs.coreutils}/bin/ln -sfn "$FRONTEND_RELEASE" "${frontendRoot}/current"

    echo "==> Ownership korrigieren"
    ${pkgs.coreutils}/bin/chown -R ${appUser}:${appGroup} "${appRoot}"

    echo "==> Services neu laden"
    ${pkgs.systemd}/bin/systemctl restart homesuite-backend.service
    ${pkgs.systemd}/bin/systemctl reload nginx.service || true

    echo "==> Health-Check"
    HEALTH_OK=0
    for _ in $(${pkgs.coreutils}/bin/seq 1 30); do
      if ${pkgs.curl}/bin/curl -fsS --max-time 2 http://127.0.0.1:5000/health >/dev/null 2>&1; then
        HEALTH_OK=1
        break
      fi
      ${pkgs.coreutils}/bin/sleep 2
    done

    if [ "$HEALTH_OK" -ne 1 ]; then
      echo "Backend meldet sich nach dem Deploy nicht healthy (http://127.0.0.1:5000/health)." >&2
      ${pkgs.systemd}/bin/systemctl status homesuite-backend.service --no-pager >&2 || true
      exit 1
    fi
    echo "Backend ist healthy."

    echo "==> Alte Releases aufräumen (die letzten 5 bleiben)"
    for RELEASE_DIR in "${backendRoot}/releases" "${frontendRoot}/releases"; do
      ${pkgs.coreutils}/bin/ls -1 "$RELEASE_DIR" | ${pkgs.coreutils}/bin/sort | ${pkgs.coreutils}/bin/head -n -5 | while IFS= read -r OLD_RELEASE; do
        ${pkgs.coreutils}/bin/rm -rf "$RELEASE_DIR/$OLD_RELEASE"
      done
    done
  '';

  migrateScript = pkgs.writeShellScriptBin "homesuite-migrate" ''
    #!${pkgs.bash}/bin/bash
    set -Eeuo pipefail

    SRC_ROOT=${escapeShellArg cfg.sourceRoot}
    BACKEND_SRC="$SRC_ROOT/backend"
    INFRA_PROJECT="$BACKEND_SRC/src/HomeSuite.Infrastructure/HomeSuite.Infrastructure.csproj"
    API_PROJECT="$BACKEND_SRC/src/HomeSuite.API/HomeSuite.API.csproj"

    export HOME="${appRoot}/.deploy-home"
    export ASPNETCORE_ENVIRONMENT=Production
    export PATH=${escapeShellArg toolPath}:$PATH

    export ConnectionStrings__DefaultConnection=${escapeShellArg defaultConnectionString}

    if [ -n ${escapeShellArg environmentFilePath} ] && [ -f ${escapeShellArg environmentFilePath} ]; then
      set -a
      source ${escapeShellArg environmentFilePath}
      set +a
    fi

    if [ ! -f "$INFRA_PROJECT" ]; then
      echo "Infrastructure project fehlt: $INFRA_PROJECT" >&2
      exit 1
    fi

    if [ ! -f "$API_PROJECT" ]; then
      echo "API project fehlt: $API_PROJECT" >&2
      exit 1
    fi

    if [ -z "''${ConnectionStrings__DefaultConnection:-}" ]; then
      echo "ConnectionStrings__DefaultConnection fehlt. Prüfe Default-DB oder optionales EnvironmentFile." >&2
      exit 1
    fi

    cd "$BACKEND_SRC"
    ${pkgs.dotnetCorePackages.sdk_8_0}/bin/dotnet build "$API_PROJECT" -c Release --nologo
    ${pkgs.dotnet-ef}/bin/dotnet-ef database update \
      --project "$INFRA_PROJECT" \
      --startup-project "$API_PROJECT"
  '';
in
{
  options.services.homesuite = {
    sourceRoot = mkOption {
      type = types.str;
      default = "/home/${username}/homesuite";
      example = "/home/jakob/homesuite";
      description = "Local HomeSuite checkout used by the manual deploy and migration commands.";
    };

    environmentFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Optional environment file used by the runtime backend service and migration command.
        Use this for real secrets: a `ConnectionStrings__DefaultConnection` entry here
        overrides the default connection string built from the (world-readable) nix store.
      '';
    };

    database = {
      name = mkOption {
        type = types.str;
        default = "homesuite";
        description = "Local PostgreSQL database name for HomeSuite.";
      };

      user = mkOption {
        type = types.str;
        default = "homesuite";
        description = "Local PostgreSQL user for HomeSuite.";
      };

      password = mkOption {
        type = types.str;
        default = "homesuite";
        description = ''
          Local PostgreSQL password for HomeSuite. WARNING: this value ends up
          world-readable in the nix store. Acceptable for the localhost-only default DB;
          for anything sensitive set the connection string via `environmentFile` instead.
        '';
      };

      port = mkOption {
        type = types.port;
        default = 5432;
        description = "Local PostgreSQL port for HomeSuite.";
      };
    };
  };

  config = mkIf config.machineProfiles.server.homesuite.enable {
    users.groups.${appGroup} = {};

    users.users.${appUser} = {
      isSystemUser = true;
      group = appGroup;
      home = "/var/empty";
      createHome = false;
      description = "HomeSuite service user";
    };

    environment.systemPackages = [
      deployScript
      migrateScript
      pkgs.postgresql
    ];

    services.postgresql = {
      enable = true;
      ensureDatabases = [ cfg.database.name ];
      ensureUsers = [
        {
          name = cfg.database.user;
          ensureClauses = {
            login = true;
            password = cfg.database.password;
          };
        }
      ];
      settings = {
        port = cfg.database.port;
      };
      authentication = lib.mkAfter ''
        local ${cfg.database.name} ${cfg.database.user} scram-sha-256
        host  ${cfg.database.name} ${cfg.database.user} 127.0.0.1/32 scram-sha-256
        host  ${cfg.database.name} ${cfg.database.user} ::1/128 scram-sha-256
      '';
    };

    systemd.tmpfiles.rules = [
      "d ${appRoot} 0755 ${appUser} ${appGroup} - -"
      "d ${appRoot}/.deploy-home 0755 root root - -"
      "d ${appRoot}/.runtime-home 0750 ${appUser} ${appGroup} - -"
      "d ${backendRoot} 0755 ${appUser} ${appGroup} - -"
      "d ${backendRoot}/releases 0755 ${appUser} ${appGroup} - -"
      "d ${frontendRoot} 0755 ${appUser} ${appGroup} - -"
      "d ${frontendRoot}/releases 0755 ${appUser} ${appGroup} - -"
    ];

    systemd.services.homesuite-backend = {
      description = "HomeSuite ASP.NET backend";
      after = [ "network-online.target" "postgresql.service" ];
      wants = [ "network-online.target" "postgresql.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig =
        {
          Type = "simple";
          User = appUser;
          Group = appGroup;
          WorkingDirectory = "${backendRoot}/current";
          ExecStart = "${pkgs.dotnetCorePackages.aspnetcore_8_0}/bin/dotnet ${backendRoot}/current/${backendDll}";
          Restart = "always";
          RestartSec = "5s";
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectSystem = "strict";
          # "read-only" statt true, damit der Preis-Crawler das HomeSuite-Checkout
          # (cfg.sourceRoot) für die Playwright-Suche lesen kann.
          ProtectHome = "read-only";
          ReadWritePaths = [ appRoot ];
        }
        // lib.optionalAttrs (cfg.environmentFile != null) {
          EnvironmentFile = cfg.environmentFile;
        };
      environment = {
        ASPNETCORE_ENVIRONMENT = "Production";
        ConnectionStrings__DefaultConnection = defaultConnectionString;
        # Playwright-Store-Suche: Checkout mit flake.nix + scripts/, sonst läuft
        # der Crawler nur mit dem DuckDuckGo-Fallback.
        CatalogCrawler__SourceRoot = cfg.sourceRoot;
        CatalogCrawler__NixExecutablePath = "/run/current-system/sw/bin/nix";
        # Schreibbares HOME für nix develop / Chromium (Service-User hat /var/empty).
        HOME = "${appRoot}/.runtime-home";
      };
    };

    systemd.services.homesuite-deploy = {
      description = "Build and deploy HomeSuite backend and frontend";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        Type = "oneshot";
        User = "root";
        Group = "root";
        ExecStart = "${deployScript}/bin/homesuite-deploy";
      };
    };

    systemd.services.homesuite-migrate = {
      description = "Run HomeSuite Entity Framework migrations";
      after = [ "network-online.target" "postgresql.service" ];
      wants = [ "network-online.target" "postgresql.service" ];

      serviceConfig = {
        Type = "oneshot";
        User = "root";
        Group = "root";
        ExecStart = "${migrateScript}/bin/homesuite-migrate";
      };
    };
  };
}
