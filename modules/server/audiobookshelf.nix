{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.machineProfiles.audiobookshelf;
in
{
  config = lib.mkIf cfg.enable {
    virtualisation.docker.enable = true;
    virtualisation.oci-containers.backend = "docker";

    virtualisation.oci-containers.containers.audiobookshelf = {
      image = "ghcr.io/advplyr/audiobookshelf:latest";
      ports = [ "13378:80" ];
      environment = {
        TZ = "Europe/Vienna";
      };
      volumes = [
        "/home/jakob/NAStalavista/Audiobookshelf/Books:/audiobooks"
        "/home/jakob/audiobookshelf/Podcast:/podcasts"
        "/home/jakob/audiobookshelf/config:/config"
        "/home/jakob/audiobookshelf/metadata:/metadata"
      ];
    };
  };
}
