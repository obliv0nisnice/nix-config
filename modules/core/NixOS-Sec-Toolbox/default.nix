{ config, lib, pkgs, ... }:

let
  enable = config.NixOS-Sec-Toolbox.enable or false;
in
{
  options.NixOS-Sec-Toolbox.enable = lib.mkEnableOption "NixOS Security Toolbox";

  config = lib.mkIf enable
    (lib.mkMerge (map (f: import (./. + "/${f}") { inherit config lib pkgs; }) [
      "bluetooth.nix"
      "cloud.nix"
      "code.nix"
      "container.nix"
      "dns.nix"
      "exploits.nix"
      "forensics.nix"
      "fuzzers.nix"
      "generic.nix"
      "hardware.nix"
      "host.nix"
      "information-gathering.nix"
      "kubernetes.nix"
      "ldap.nix"
      "load-testing.nix"
      "malware.nix"
      "misc.nix"
      "mobile.nix"
      "network.nix"
      "packet-generators.nix"
      "password.nix"
      "port-scanners.nix"
      "proxies.nix"
      "services.nix"
      "smartcards.nix"
      "terminals.nix"
      "tls.nix"
      "traffic.nix"
      "tunneling.nix"
      "voip.nix"
      "web.nix"
      "windows.nix"
      "wireless.nix"
    ]));
}

