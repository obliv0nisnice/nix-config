# Music Assistant: Musik über richtige Lautsprecher, Satelliten sprechen nur.
# Weitere Quellen/Player (spotify, snapcast, …) bei Bedarf in `providers` ergänzen.
{ config, lib, ... }:
{
  config = lib.mkIf config.machineProfiles.server.assistant.musicAssistant.enable {
    services.music-assistant = {
      enable = true;
      # Web-UI :8095 und Stream-Server – Player im LAN holen den Audiostream hier ab.
      openFirewall = true;
      providers = [
        "hass"
        "hass_players"
        "airplay"
        "chromecast"
        "dlna"
        "wiim"
      ];
    };
  };
}
