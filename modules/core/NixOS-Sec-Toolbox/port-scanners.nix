# Port scanners

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    havn
    ipscan
    masscan
    naabu
    nmap
    udpx
    smap
    sx-go
    rustscan
    zmap
  ];
}
