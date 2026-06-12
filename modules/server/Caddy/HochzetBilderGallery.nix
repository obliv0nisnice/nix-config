let
  pkgs = import <nixpkgs> {};
  lib = pkgs.lib;
in pkgs.buildNpmPackage {
  name = "HochzeitM-M";
  src = ./HochzeitGalerie;
  npmDepsHash = "sha256-yvvMGPRFYU8RLHyThvEgjg/PGW/5f4OmDdKAmUetU9s=";
  NG_CLI_ANALYTICS="0";
  installPhase = ''
    cp -r dist/hochzeit-galerie/browser $out
  '';
}
