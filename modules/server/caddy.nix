{ config, pkgs, ... }:

let
  website = import ./Caddy/mywebsite.nix;
  mail = import ./Caddy/mailserver.nix;
  hochzeit = import ./Caddy/HochzeitBilderGallery;
in {
  services.caddy = {
    enable = true;

    virtualHosts."nestler.duckdns.org" = {
      extraConfig = ''
        log {
          output file /home/jakob/github/projects/HomeDepot/Caddy/access.log
        }
        encode gzip
        file_server
        root * ${website}

        reverse_proxy /api* http://localhost:5000
      '';
    };
    virtualHosts."mailnestler.duckdns.org" = {
	extraConfig = ''	
	  encode gzip
	  root * ${mail}
	  '';
	};
      };
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}

