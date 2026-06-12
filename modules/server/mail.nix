{ config, pkgs, ... }: {
  imports = [
    (builtins.fetchTarball {
      # Wähle eine Release-Version aus, die dich interessiert, und setze ihren Hash, z.B.
      url = "https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/-/archive/nixos-23.05/nixos-mailserver-nixos-23.05.tar.gz";
      # Um den sha256 des nixos-mailserver Tarballs zu erhalten, können wir das nix-prefetch-url-Kommando verwenden:
      # release="nixos-23.05"; nix-prefetch-url "https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/-/archive/${release}/nixos-mailserver-${release}.tar.gz" --unpack
      sha256 = "1ngil2shzkf61qxiqw11awyl81cr7ks2kv3r3k243zz7v2xakm5c";
    })
  ];

  mailserver = {
    enable = true;
    fqdn = "mailnestler.duckdns.org";
    domains = [ "mailnestler.duckdns.org" ];

    # Eine Liste aller Login-Accounts. Um die Passworthashes zu erstellen, verwenden Sie
    # nix-shell -p mkpasswd --run 'mkpasswd -sm bcrypt'
    loginAccounts = {
      "user1@mailnestler.duckdns.org" = {
        hashedPasswordFile = "/home/jakob/hashedPW/user1.txt";
        aliases = ["postmaster@mailnestler.duckdns.org"];
      };
    };
  certificateScheme = "manual";
  certificateFile = "/var/lib/acme/mailnestler.duckdns.org/cert.pem";
  keyFile = "/var/lib/acme/mailnestler.duckdns.org/key.pem";
  };

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "security@mailnestler.duckdns.org";
 }

