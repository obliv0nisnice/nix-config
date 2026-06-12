# Password and hashing tools

{
  config,
  lib,
  pkgs,
  ...
}:
let
  hashcatPackage =
    if (config.drivers.nvidia.enable or false) then
      pkgs.symlinkJoin {
        name = "hashcat-cuda-wrapped";
        paths = [ pkgs.hashcat ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/hashcat \
            --set-default CUDA_PATH ${pkgs.cudaPackages.cudatoolkit} \
            --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [
              pkgs.cudaPackages.cudatoolkit
              pkgs.cudaPackages.cuda_cudart
              pkgs.cudaPackages.cuda_nvrtc
            ]}:/run/opengl-driver/lib:/etc/sane-libs"
        '';
      }
    else
      pkgs.hashcat;
in
{
  environment.systemPackages = with pkgs; [
    authoscope
    bruteforce-luks
    conpass
    crunch
    h8mail
    hashcatPackage
    hashcat-utils
    hashdeep
    john
    legba
    nasty
    nth
    thc-hydra
    truecrack
    hashid
  ];
}
