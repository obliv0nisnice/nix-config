{
  config,
  lib,
  pkgs,
  ...
}:

{
config = lib.mkIf config.machineProfiles.adguard.enable {
services.adguardhome =  {
    enable = true;
    openFirewall = true;
    port = 3003;
    settings = {
     # http = {
     #   address = "127.0.0.1:3003";
     # };
      dns = {
        upstream_dns = [
          "https://dns.adguard-dns.com/dns-query"
	        "https://dns.cloudflare.com/dns-query"
        ];
      };
      filtering = {
        protection_enabled = true;
        filtering_enabled = true;

        parental_enabled = false;
        safe_search = {
          enabled = false;
        };

        rewrites = [
          { enabled = true; domain = "MeineMagischeWlanBox.nestlerlabs.at"; answer = "192.168.1.1"; }
          { enabled = true; domain = "immich.nestlerlabs.at"; answer = "192.168.1.119"; }
	  { enabled = true; domain = "adguard.nestlerlabs.at"; answer = "192.168.1.119"; }
	  { enabled = true; domain = "NAStalavista.nestlerlabs.at"; answer = "192.168.1.125"; }
	  { enabled = true; domain = "jellyfin.nestlerlabs.at"; answer = "192.168.1.119"; }
	  { enabled = true; domain = "homesuite.nestlerlabs.at"; answer = "192.168.1.119"; }
	  { enabled = true; domain = "sonarqube.nestlerlabs.at"; answer = "192.168.1.119"; }
	  { enabled = true; domain = "audiobookshelf.nestlerlabs.at"; answer = "192.168.1.119"; }
    { enabled = true; domain = "ca.nestlerlabs.at"; answer = "192.168.1.119"; }  
            # NEU
    { enabled = true; domain = "gitea.nestlerlabs.at"; answer = "192.168.1.119"; }  # NEU
    { enabled = true; domain = "dtrack.nestlerlabs.at"; answer = "192.168.1.119"; }  # NEU
	  
	

        ];
      };
      filters = map (url: { enabled = true; url = url; }) [
        "https://adguardteam.github.io/HostlistsRegistry/assets/filter_9.txt"
        "https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt"
      ];
    };
  };
};
}
