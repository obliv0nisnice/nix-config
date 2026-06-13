{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.machineProfiles.server.media.enable {
   fileSystems."/home/jakob/jellyfin/media" = {
    device = "//192.168.1.125/home/Jellyfin";
    fsType = "cifs";

    options = [
      # Authentication
      "credentials=/etc/samba/jellyfin.creds"

      # SMB protocol
      "vers=3.1.1"

      # Ownership for Docker / Jellyfin
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

systemd.tmpfiles.rules = [
    "d /home/jakob/jellyfin 0755 jakob users -"
    "d /home/jakob/jellyfin/config 0755 jakob users -"
    "d /home/jakob/jellyfin/cache 0755 jakob users -"
    "d /home/jakob/jellyfin/media 0755 jakob users -"
  ];
  };
}
