{...}: {
  imports = [
    ./secrets.nix
    ./nginx.nix
    ./AdguardHome.nix
    ./jellyfin.nix
    ./audiobookshelf.nix
    ./homesuite.nix
    ./certs.nix
    ./netbird.nix
    ./step-ca.nix
    ./git
  ];
}
