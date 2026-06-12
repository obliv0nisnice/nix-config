# Common network tools

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    arp-scan
    arp-scan-rs
    arping
    arpoison
    atftp
    bandwhich
    bngblaster
    cdncheck
    evillimiter
    iperf2
    iputils
    lftp
    mtr
    ncftp
    netcat-gnu
    netdiscover
    netexec
    nload
    nuttcp
    putty
    pwnat
    responder
    route-graph
    rustcat
    sshping
    sslh
    wbox
    whois
  ];
}
