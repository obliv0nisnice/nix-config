# Proxy tools for MitM scenarios

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    bettercap
    burpsuite
    ettercap
    mubeng
    proxify
    proxychains
    redsocks
    rshijack
    zap
  ];
}
