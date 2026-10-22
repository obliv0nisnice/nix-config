# Sprach-Pipeline über Wyoming, nur lokal erreichbar (Home Assistant verbindet
# sich über localhost). In HA: Integration "Wyoming" mit 127.0.0.1:10300 / :10200.
{ config, lib, pkgs, ... }:
let
  gpu = config.machineProfiles.server.assistant.gpu.enable;

  # faster-whisper nutzt CUDA nur mit einem CUDA-gebauten ctranslate2.
  # Wird lokal gebaut (kein Binary-Cache für CUDA) – erster Rebuild dauert.
  whisperCuda = pkgs.wyoming-faster-whisper.override {
    python3Packages = pkgs.python3Packages.overrideScope (_: prev: {
      ctranslate2 = prev.ctranslate2.override {
        ctranslate2-cpp = pkgs.ctranslate2.override {
          withCUDA = true;
          withCuDNN = true;
        };
      };
    });
  };
in
{
  config = lib.mkIf config.machineProfiles.server.assistant.voice.enable {
    services.wyoming.faster-whisper = {
      package = lib.mkIf gpu whisperCuda;
      servers.de = {
        enable = true;
        language = "de";
        uri = "tcp://127.0.0.1:10300";
        # Kleine Modelle sind auf Deutsch schwach -> mit GPU das große Modell.
        device = if gpu then "cuda" else "cpu";
        model = if gpu then "large-v3-turbo" else "auto";
      };
    };

    services.wyoming.piper.servers.de = {
      enable = true;
      voice = "de_DE-thorsten-high";
      uri = "tcp://127.0.0.1:10200";
    };
  };
}
