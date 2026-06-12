let
  pkgs = import <nixpkgs> {};
in pkgs.buildNpmPackage {
  name = "jakobs-toller-mailserver";
  src = ./mailserver;
  npmDepsHash = lib.fakeHash;
  installPhase = ''
    cp -r public $out
  '';
}
