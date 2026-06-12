{ stdenv, lib, fetchurl, nodejs }:

stdenv.mkDerivation rec {
  pname = "jakobs-toller-mailserver";
  version = "1.0.0";

  src = ./.;

  buildInputs = [ nodejs ];

  dontNpmBuild = true;

  installPhase = ''
    mkdir -p $out/libexec/${pname}
    # Copy the existing project files
    cp -r * $out/libexec/${pname}/ || true
  '';
}

