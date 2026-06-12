{ config, pkgs, ... }:

{

  environment.systemPackages = with pkgs; [
    proxychains-ng
    curl
    tor
  ];

   services.tor = {
    enable = true;
    client.enable = true;
  };

    environment.etc."proxychains.conf".text = ''
    ########################################
    # ProxyChains Configuration (Dummy)
    ########################################

    # Kettenmodus:
    # strict_chain | dynamic_chain | random_chain
    dynamic_chain

    # DNS über Proxy auflösen
    proxy_dns

    tcp_read_time_out 15000
    tcp_connect_time_out 8000

    ########################################
    # Proxy Liste
    ########################################
    [ProxyList]

    # Lokaler Tor SOCKS Proxy (Dummy / Standard)
    socks5  127.0.0.1 9050

    # Dummy SOCKS5 Proxy (Dokunetz RFC 5737)
    socks5  192.0.2.10 1080

    # Dummy HTTP Proxy
    http    198.51.100.20 8080
  '';
}
