{ pkgs, ... }:

pkgs.buildNpmPackage {
  name = "jakobs-tolle-seite";
  src = ./website;

  npmDepsHash = "sha256-4rmNYjRQ+Q4eQaDMHu68Yz3m0ydqS22pCHhFFvGA61c=";

  installPhase = ''
    cp -r public $out
  '';
}
