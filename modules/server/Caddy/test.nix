let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-23.11";
  pkgs = import nixpkgs { config = {}; overlays = []; };
  mywebsite = import ./mywebsite.nix;
in

pkgs.nixosTest {
  name = "minimal-test";

  nodes.machine = { config, pkgs, ... }: {
    services.caddy = {
      enable = true;
      virtualHosts."localhost".extraConfig = ''
        encode gzip
        file_server
        root * ${mywebsite}
      '';
    };
    system.stateVersion = "23.11";
  };

  testScript = ''
    machine.wait_for_unit("default.target")
    machine.succeed("su -- root -c 'ls ${mywebsite}'")
    machine.succeed("su -- root -c 'cat ${mywebsite}/index.html'")
    machine.succeed("su -- root -c 'curl localhost:80'")
  '';
}
