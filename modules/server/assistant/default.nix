# Lokaler Sprachassistent (Konzept: homelab-voice-assistant-konzept.md).
# Jeder Teil hat einen eigenen Schalter unter machineProfiles.server.assistant.*
# in hosts/<host>/variables.nix.
{ ... }:
{
  imports = [
    ./gpu.nix
    ./home-assistant.nix
    ./voice.nix
    ./ollama.nix
    ./music-assistant.nix
    ./ntfy.nix
    ./brain-db.nix
  ];
}
