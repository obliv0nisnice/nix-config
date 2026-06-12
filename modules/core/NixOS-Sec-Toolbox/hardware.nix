# Tools and libraries to access hardware

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    cantoolz
    chipsec
    cmospwd
    esptool
    extrude
    gallia
    hachoir
    nrfutil #needs special license
    packetry
    teensy-loader-cli
    termineter
    tytools
    python3Packages.python-can
    python3Packages.pyi2cflash
    python3Packages.pyspiflash
    # routersploit
  ];
  nixpkgs.config.segger-jlink.acceptLicense = true; #for nrfutil
}
