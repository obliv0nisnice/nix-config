# ntfy: Push-Nachrichten mit Action-Buttons (Bestätigungen für sensible Aktionen).
# Zugriff nur mit Login: Benutzer anlegen mit `sudo ntfy user add --role=admin <name>`.
{ config, lib, ... }:
let
  profiles = config.machineProfiles.server;
in
{
  config = lib.mkIf profiles.assistant.ntfy.enable {
    services.ntfy-sh = {
      enable = true;
      settings = {
        base-url = "https://ntfy.nestlerlabs.at";
        listen-http = "127.0.0.1:2586";
        behind-proxy = true;
        auth-file = "/var/lib/ntfy-sh/user.db";
        auth-default-access = "deny-all";
      };
    };

    services.nginx.virtualHosts."ntfy.nestlerlabs.at" = lib.mkIf profiles.reverseProxy.enable {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:2586";
        proxyWebsockets = true;
      };
    };
  };
}
