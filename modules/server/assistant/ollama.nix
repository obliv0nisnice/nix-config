# Lokales LLM für Router + Agent. Nur an localhost gebunden; der Brain spricht
# es über http://127.0.0.1:11434 an.
{ config, lib, pkgs, ... }:
let
  assistant = config.machineProfiles.server.assistant;
in
{
  config = lib.mkIf assistant.ollama.enable {
    assertions = [
      {
        assertion = assistant.gpu.enable;
        message = "machineProfiles.server.assistant.ollama braucht assistant.gpu (RTX 5060 Ti).";
      }
    ];

    services.ollama = {
      enable = true;
      package = pkgs.ollama-cuda;
      host = "127.0.0.1";
      # Startmodell laut Konzept – Tag vor dem Einschalten auf ollama.com prüfen.
      loadModels = [ "qwen3.5:9b" ];
      # Modell dauerhaft im VRAM halten, kein Nachladen im Sprachpfad.
      environmentVariables.OLLAMA_KEEP_ALIVE = "-1";
    };
  };
}
