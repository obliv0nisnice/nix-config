{ vars, ... }:
let
  inherit (vars) gitUsername gitEmail;
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
