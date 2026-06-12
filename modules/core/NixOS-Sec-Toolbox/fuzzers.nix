# Fuzzing tools

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    aflplusplus
    feroxbuster
    ffuf
    gobuster
    radamsa
    regexploit
    scout
    ssdeep
    zzuf
  ];
}
