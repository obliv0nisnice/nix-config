{ lib, config, username, ... }:

with lib;

let
  cfg = config.NASMount;
in
{
  options.NASMount = {
    enable = mkEnableOption "Mount NAS CIFS share for user home directory";
  };

  config = mkIf cfg.enable {

    fileSystems."/home/${username}/NAStalavista" = {
      device = "//192.168.1.125/home/";
      fsType = "cifs";

      options = [
        # Authentication
        "credentials=/etc/samba/smb.creds"

        # SMB protocol
        "vers=3.1.1"

        # Ownership (Docker / Jellyfin compatible)
        "uid=1000"
        "gid=1000"

        # Permission mapping
        "file_mode=0644"
        "dir_mode=0755"

        # Encoding & inode handling
        "iocharset=utf8"
        "noserverino"

        # Systemd behavior
        "nofail"
        "x-systemd.automount"
      ];
    };

  };
}

