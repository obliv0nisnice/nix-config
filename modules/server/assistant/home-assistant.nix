# Home Assistant: Geräte-Hub und Assist-Pipeline (nicht das Gehirn).
# Onboarding (Name, Standort, Benutzer) passiert beim ersten Aufruf im Browser.
{ config, lib, ... }:
let
  profiles = config.machineProfiles.server;
in
{
  config = lib.mkIf profiles.assistant.homeAssistant.enable {
    # Satelliten holen TTS-Audio direkt über :8123 im LAN (HA-Standardport).
    networking.firewall.allowedTCPPorts = [ 8123 ];

    services.home-assistant = {
      enable = true;
      extraComponents = [
        "default_config"
        "met"
        "esphome" # Voice PE / ESPHome-Satelliten
        "wyoming" # faster-whisper + Piper (voice.nix)
        "music_assistant"
        "mcp_server" # Geräte/Szenen als MCP-Tools für Brain und Claude
      ];
      config = {
        default_config = { };
        http = {
          use_x_forwarded_for = true;
          trusted_proxies = [ "127.0.0.1" "::1" ];
        };
      };
    };

    services.nginx.virtualHosts."ha.nestlerlabs.at" = lib.mkIf profiles.reverseProxy.enable {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8123";
        proxyWebsockets = true;
      };
    };
  };
}
