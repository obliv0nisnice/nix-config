# Tools for informtion gathering

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    cloudbrute
    enumerepo
    holehe
    # maigret disabled: currently pulls insecure pypdf2 in nixpkgs
    metabigor
    sn0int
    socialscan
    urlhunter
  ];
}
