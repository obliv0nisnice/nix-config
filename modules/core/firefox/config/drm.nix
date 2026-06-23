{
  # DRM / Widevine – nur die generische Aktivierung. Auf x86-Hosts reicht das:
  # Firefox lädt das Widevine-CDM (Google liefert es nur als x86_64) bei Bedarf
  # selbst nach. Auf Apple Silicon geht das nicht – dort legt
  # modules/apple-silicon/firefox-widevine.nix den lokal extrahierten aarch64-
  # Plugin-Pfad drüber (MOZ_GMP_PATH + media.gmp-widevinecdm.version) und
  # überschreibt damit das Auto-Download-Verhalten.

  # Enables playback of DRM-controlled HTML5 content. If enabled, automatically
  # downloads the Widevine Content Decryption Module provided by Google Inc.
  # (https://support.mozilla.org/en-US/kb/enable-drm)
  "media.eme.enabled" = true;
  # Enables the Widevine Content Decryption Module provided by Google Inc., used
  # for the playback of DRM-controlled HTML5 content.
  "media.gmp-widevinecdm.enabled" = true;
}
