{...}: {
  imports = [
    ./secrets.nix
    ./nginx.nix
    ./AdguardHome.nix
    ./jellyfin.nix
    ./audiobookshelf.nix
    ./homesuite.nix
    ./certs.nix
    ./step-ca.nix
    ./git
    ./assistant
  ];
}
