# Host security tools

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    checksec
    linux-exploit-suggester
    lynis
    safety-cli
    #tracee
    vulnix
  ];
}
