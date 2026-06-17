# Natives Widevine/DRM für Firefox auf Apple Silicon (aarch64/Asahi).
#
# Google liefert Widevine für Linux nur als x86_64 aus; der native Firefox kann
# es daher nicht selbst nachladen. nixpkgs' `widevine-cdm` extrahiert stattdessen
# das aarch64-Widevine aus einem ChromeOS-Lacros-Image und jagt es durch Asahis
# `widevine_fixup.py` – das ist der entscheidende Patch, der die .so auf Kerneln
# mit 16k-Pages (Apple Silicon) lauffähig macht.
#
# nixpkgs legt das Ganze im Chromium-Layout ab (share/google/chrome/...). Firefox
# erwartet aber das GMP-Layout `<dir>/gmp-widevinecdm/<version>/` mit manifest.json
# + libwidevinecdm.so, auf das MOZ_GMP_PATH zeigt. Das manifest.json aus ChromeOS
# enthält bereits die von Firefox benötigten x-cdm-*-Felder, lässt sich also direkt
# weiterverwenden.
#
# DRM selbst (media.eme.enabled / media.gmp-widevinecdm.enabled) ist bereits im
# gemeinsamen Firefox-Modul aktiviert; hier kommt nur der aarch64-spezifische
# Plugin-Pfad dazu. Nur als macbook-Modul importiert → trifft keine x86-Hosts.
{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  widevine = pkgs.widevine-cdm;
  gmpVersion = "system-installed";
  # ChromeOS-Layout → Firefox-GMP-Layout umbiegen.
  firefox-widevine-gmp = pkgs.runCommand "firefox-widevine-gmp" { } ''
    dir="$out/gmp-widevinecdm/${gmpVersion}"
    mkdir -p "$dir"
    ln -s ${widevine}/share/google/chrome/WidevineCdm/manifest.json "$dir/manifest.json"
    ln -s ${widevine}/share/google/chrome/WidevineCdm/_platform_specific/linux_arm64/libwidevinecdm.so "$dir/libwidevinecdm.so"
  '';
in
{
  environment.sessionVariables.MOZ_GMP_PATH = "${firefox-widevine-gmp}/gmp-widevinecdm/${gmpVersion}";

  # Firefox lädt das Plugin aus MOZ_GMP_PATH nur, wenn die Versions-Pref exakt
  # dem Verzeichnisnamen (${gmpVersion}) entspricht – sonst gilt Widevine als
  # "nicht installiert" und DRM-Seiten bleiben tot. `visible` blendet es zudem
  # in about:addons ein. media.{eme,gmp-widevinecdm}.enabled kommen aus dem
  # gemeinsamen Firefox-Modul (browser-features.nix, nur im default-Profil),
  # darum mergen wir hier in dasselbe Profil.
  home-manager.users.${username}.programs.firefox.profiles.default.settings = {
    "media.gmp-widevinecdm.version" = gmpVersion;
    "media.gmp-widevinecdm.visible" = true;
  };
}
