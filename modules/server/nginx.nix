 {
  config,
  lib,
  pkgs,
  ...
}:

let
  websiteRoot = "/home/jakob/NixOS-Config/modules/server/Caddy/mywebsite";
  homesuiteFrontend = "/var/lib/homesuite/frontend/current";
in
{
  config = lib.mkIf config.machineProfiles.reverseProxy.enable {
    security.acme = {
      acceptTerms = true;
      defaults = {
        email = "anrufen_nahm0p@icloud.com";
        server = "https://ca.nestlerlabs.at:8443/acme/acme/directory";
      };
    };

    services.nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      virtualHosts = {
        "homesuite.nestlerlabs.at" = {
          root = homesuiteFrontend;
          enableACME = true;
          forceSSL = true;
          locations."/api/" = {
            proxyPass = "http://127.0.0.1:5000";
            # Beleg-Scan: Foto-Upload (Base64) + längere Antwortzeit der Claude API
            extraConfig = ''
              client_max_body_size 25m;
              proxy_read_timeout 300s;
            '';
          };
          locations."/" = {
            tryFiles = "$uri $uri/ /index.html";
          };
        };

        "nestler.duckdns.org" = {
          root = websiteRoot;
          forceSSL = true;
          enableACME = true;

          locations."/api" = {
            proxyPass = "http://127.0.0.1:5000";
            # Beleg-Scan: Foto-Upload (Base64) + längere Antwortzeit der Claude API
            extraConfig = ''
              client_max_body_size 25m;
              proxy_read_timeout 300s;
            '';
          };
        };

        "ca.nestlerlabs.at" = {
          enableACME = true;
          forceSSL = true;
          locations."= /root_ca.crt" = {
            alias = "/etc/ssl/step-ca-root.crt";
            extraConfig = ''
              default_type application/x-x509-ca-cert;
              add_header Content-Disposition 'attachment; filename="step-ca-root.crt"';
            '';
          };
          locations."/" = {
            return = "302 /root_ca.crt";
          };
        };

        "adguard.nestlerlabs.at" = {
          enableACME = true;
          forceSSL = true;
          locations."/".proxyPass = "http://localhost:3003";
        };

        "jellyfin.nestlerlabs.at" = {
          enableACME = true;
          forceSSL = true;
          locations."/".proxyPass = "http://localhost:8096";
        };

        "audiobookshelf.nestlerlabs.at" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://localhost:13378";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
            '';
          };
        };

        "sonarqube.nestlerlabs.at" = {
          enableACME = true;
          forceSSL = true;
          extraConfig = ''
            client_max_body_size 100m;
          '';
          locations."/" = {
            proxyPass = "http://127.0.0.1:9000";
            proxyWebsockets = true;
          };
        };

        "gitea.nestlerlabs.at" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:3000";
            proxyWebsockets = true;
          };
        };

        "dtrack.nestlerlabs.at" = {
          enableACME = true;
          forceSSL = true;
          locations."/api/" = {
            proxyPass = "http://127.0.0.1:8081/api/";
            proxyWebsockets = true;
          };
          locations."/" = {
            proxyPass = "http://127.0.0.1:8082/";
            proxyWebsockets = true;
          };
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };
}
