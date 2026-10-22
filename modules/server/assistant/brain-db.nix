# Datenbank für den Brain: Job-Queue, Memory (pgvector), Audit-Log.
# Läuft im bestehenden Postgres mit. Passwort/TCP-Zugang folgt, sobald es den
# Brain-Container gibt (dann über sops wie bei homesuite).
{ config, lib, ... }:
let
  pg = config.services.postgresql;
in
{
  config = lib.mkIf config.machineProfiles.server.assistant.brainDb.enable {
    services.postgresql = {
      enable = true;
      extensions = ps: [ ps.pgvector ];
      ensureDatabases = [ "brain" ];
      ensureUsers = [
        {
          name = "brain";
          ensureDBOwnership = true;
        }
      ];
    };

    # CREATE EXTENSION braucht Superuser-Rechte, darum einmalig als postgres.
    systemd.services.brain-db-vector = {
      description = "Enable pgvector in the brain database";
      after = [ "postgresql-setup.service" ];
      requires = [ "postgresql-setup.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "postgres";
        ExecStart = "${pg.finalPackage}/bin/psql -d brain -c 'CREATE EXTENSION IF NOT EXISTS vector'";
      };
    };
  };
}
