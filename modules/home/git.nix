{ host, ... }:
let
  inherit (import ../../hosts/${host}/variables.nix) gitUsername gitEmail;
in
{
  programs.git = {
    enable = true;
    signing.format = "openpgp";
    settings = {
      user.name = "${gitUsername}";
      user.email = "${gitEmail}";
    };
  };
}
