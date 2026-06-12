let
  pkgs = import <nixpkgs> {};
in pkgs.buildNpmPackage {
  name = "jakobs-tolle-seite";
  src = ../HochzeitBilderGallery;
  npmDepsHash = "sha256-4rmNYjRQ+Q4eQaDMHu68Yz3m0ydqS22pCHhFFvGA61c=";
  installPhase = ''
    cp -r public $out
  '';
}
