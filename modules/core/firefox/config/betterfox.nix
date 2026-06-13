{
  # Betterfox Securefox + Peskyfox sections
  # https://github.com/yokoffing/Betterfox
  # Fastfox lives in speed.nix. Prefs that another file in this directory
  # already sets (telemetry, pocket, safebrowsing, ...) are kept there and
  # intentionally omitted here, so every pref has exactly one owner.

  # SECTION: SECUREFOX
  ## TRACKING PROTECTION
  "browser.contentblocking.category" = "strict";
  "privacy.trackingprotection.allow_list.baseline.enabled" = true;
  "privacy.trackingprotection.allow_list.convenience.enabled" = true;
  "browser.download.start_downloads_in_tmp_dir" = true;
  "browser.helperApps.deleteTempFileOnExit" = true;
  "browser.uitour.enabled" = false;
  "privacy.globalprivacycontrol.enabled" = true;

  ## OCSP & CERTS / HPKP
  "security.OCSP.enabled" = 0;
  "security.pki.crlite_mode" = 2;
  "security.csp.reporting.enabled" = false;

  ## SSL / TLS
  "security.ssl.treat_unsafe_negotiation_as_broken" = true;
  "browser.xul.error_pages.expert_bad_cert" = true;
  "security.tls.enable_0rtt_data" = false;

  ## DISK AVOIDANCE
  "browser.privatebrowsing.forceMediaMemoryCache" = true;
  "browser.sessionstore.interval" = 60000;

  ## SHUTDOWN & SANITIZING
  "browser.privatebrowsing.resetPBM.enabled" = true;
  "privacy.history.custom" = true;

  ## SEARCH / URL BAR
  "browser.urlbar.trimHttps" = true;
  "browser.urlbar.untrimOnUserInteraction.featureGate" = true;
  "browser.search.separatePrivateDefault.ui.enabled" = true;
  "browser.formfill.enable" = false;

  ## PASSWORDS
  "signon.formlessCapture.enabled" = false;
  "signon.privateBrowsingCapture.enabled" = false;
  "network.auth.subresource-http-auth-allow" = 1;
  "editor.truncate_user_pastes" = false;

  ## MIXED CONTENT + CROSS-SITE
  "security.mixed_content.block_display_content" = true;

  ## EXTENSIONS
  "extensions.enabledScopes" = 5;

  ## HEADERS / REFERERS
  "network.http.referer.XOriginTrimmingPolicy" = 2;

  ## CONTAINERS
  "privacy.userContext.ui.enabled" = true;

  ## MOZILLA
  "permissions.default.desktop-notification" = 2;
  "permissions.default.geo" = 2;
  "geo.provider.network.url" = "https://beacondb.net/v1/geolocate";
  "browser.search.update" = false;
  "permissions.manager.defaultsUrl" = "";

  # SECTION: PESKYFOX
  ## MOZILLA UI
  "browser.privatebrowsing.vpnpromourl" = "";
  "extensions.htmlaboutaddons.recommendations.enabled" = false;
  "browser.discovery.enabled" = false;
  "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
  "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
  "browser.preferences.moreFromMozilla" = false;
  "browser.aboutwelcome.enabled" = false;
  "browser.profiles.enabled" = true;

  ## THEME ADJUSTMENTS
  "browser.compactmode.show" = true;
  "browser.privateWindowSeparation.enabled" = false; # WINDOWS

  ## AI
  "browser.ml.enable" = false;
  "browser.ml.chat.enabled" = false;

  ## FULLSCREEN NOTICE
  "full-screen-api.transition-duration.enter" = "0 0";
  "full-screen-api.transition-duration.leave" = "0 0";
  "full-screen-api.warning.timeout" = 0;

  ## URL BAR
  "browser.urlbar.trending.featureGate" = false;

  ## NEW TAB PAGE
  "browser.newtabpage.activity-stream.default.sites" = "";
  "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
  "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
  "browser.newtabpage.activity-stream.showSponsored" = false;
  "browser.newtabpage.activity-stream.showSponsoredCheckboxes" = false;

  ## DOWNLOADS
  "browser.download.manager.addToRecentDocs" = false;

  ## TAB BEHAVIOR
  "browser.bookmarks.openInTabClosesMenu" = false;
  "browser.menu.showViewImageInfo" = true;
  "findbar.highlightAll" = true;
  "layout.word_select.eat_space_to_next_word" = false;
}
