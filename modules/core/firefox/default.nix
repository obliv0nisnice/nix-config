{
  pkgs,
  lib,
  osConfig,
  ...
}:
let

  base16 = osConfig.stylix.base16Scheme;
  merge = lib.foldr (a: b: a // b) { };
  # later entries override earlier ones on conflict
  privacySettings = [
    (import ./config/preferences.nix)
    (import ./config/browser-features.nix)
    (import ./config/privacy.nix)
    (import ./config/tracking.nix)
    (import ./config/security.nix)
    (import ./config/speed.nix)
    (import ./config/betterfox.nix)
  ];
  # `drivers.nvidia` only exists on hosts that import modules/drivers (the x86
  # GPU stack); the macbook profile omits it, so fall back to false there.
  nvidiaSettings = lib.optionals (osConfig.drivers.nvidia.enable or false) [
    (import ./config/nvidia-fixes.nix)
  ];
  privacyExtensions = with pkgs.nur.repos.rycee.firefox-addons; [
    clearurls
    #darkreader
    sponsorblock
    ublock-origin
    keepassxc-browser
    youtube-nonstop
    sidebery
    vimium
    user-agent-string-switcher
  ];
  search = {
    default = "ddg";
    force = true;
    engines = {
      # don't need these default ones
      "amazondotcom-us".metaData.hidden = true;
      "bing".metaData.hidden = true;
      "ebay".metaData.hidden = true;

      "ddg" = {
        urls = [
          {
            template = "https://duckduckgo.com";
            params = [
              {
                name = "q";
                value = "{searchTerms}";
              }
            ];
          }
        ];
        definedAliases = [ ",d" ];
      };
      "Nix Packages" = {
        urls = [
          {
            template = "https://search.nixos.org/packages";
            params = [
              {
                name = "type";
                value = "packages";
              }
              {
                name = "query";
                value = "{searchTerms}";
              }
            ];
          }
        ];
        definedAliases = [ ",n" ];
      };
      "Wikipedia" = {
        urls = [
          {
            template = "https://en.wikipedia.org/wiki/Special:Search";
            params = [
              {
                name = "search";
                value = "{searchTerms}";
              }
            ];
          }
        ];
        definedAliases = [ ",w" ];
      };
      "GitHub" = {
        urls = [
          {
            template = "https://github.com/search";
            params = [
              {
                name = "q";
                value = "{searchTerms}";
              }
            ];
          }
        ];
        definedAliases = [ ",gh" ];
      };
    };
  };
  userChrome = ''
    /* Hide tab bar. Used with Sidebery */
    #TabsToolbar {
      visibility: collapse !important;
    }

    #navigator-toolbox:not(:hover):not(:focus-within):has(#toolbar-menubar[inactive]) {
      margin-top: -36px;
    }
    /*
    #nav-bar {
      height: 20px;
    }
    #urlbar {
      margin-top: -2px;
      font-size: 10px;
      padding-left: 5px;
      min-height: 16px;
      height: 16px;
    }
    #urlbar-searchmode-switcher {
      display: none !important;
    }
    */
    browser[type="content-primary"], 
    browser[type="content"],
    .browserContainer {
      background-color: #${base16.base01} !important;
      background: #${base16.base01} !important;
    }
  '';
in
{
  stylix = lib.mkIf osConfig.stylix.enable {
    targets.firefox = {
      profileNames = [ "default" ];
      colorTheme.enable = true;
    };
  };
  programs.firefox = lib.mkIf osConfig.machineProfiles.desktop.enable {
    enable = true;
    policies = {
      DisableTelemetry = true;
      DontCheckDefaultBrowser = true;
      DisablePocket = true;
      DisableFirefoxStudies = true;
      DisableFeedbackCommands = true;
      Extensions = {
        Uninstall = [
          "google@search.mozilla.org"
          "bing@search.mozilla.org"
          "amazondotcom@search.mozilla.org"
          "ebay@search.mozilla.org"
          "wikipedia@search.mozilla.org"
          "webcompat-reporter@mozilla.org"
          "addons-search-detection@mozilla.com"
        ];
      };
      ExtensionSettings = {
        "google@search.mozilla.org".installation_mode = "blocked";
        "bing@search.mozilla.org".installation_mode = "blocked";
        "amazondotcom@search.mozilla.org".installation_mode = "blocked";
        "ebay@search.mozilla.org".installation_mode = "blocked";
        "wikipedia@search.mozilla.org".installation_mode = "blocked";
        "{5cd68d86-8324-4ab2-9e0d-3afcc60bee5f}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/animated-pekora-dark-theme/latest.xpi";
          installation_mode = "force_installed";
        };
      };
    };
    profiles = {
      default = {
        name = "privacy-friendly";
        # tracking-webaudio.nix re-enables webaudio (overrides tracking.nix)
        settings = merge (privacySettings ++ [ (import ./config/tracking-webaudio.nix) ] ++ nvidiaSettings);
        inherit userChrome;
        userContent = ''
          body:-moz-only-whitespace {
            --body-bg-color: #${base16.base01};
            background-color: #${base16.base01};
          }

          #toolbarContainer {
            --toolbar-bg-color: #${base16.base01};
          }
        '';
        # Changes the extension storage backend from IDB to json, wipes all data when switching
        extensions.force = true;
        extensions.packages = privacyExtensions;
        inherit search;
      };
      # This does not have as strict privacy settings as the default profile.
      # It uses the default firefox settings. Useful when something is not
      # working using the default profile
      shit = {
        name = "trade-privacy-for-convenience";
        id = 1;
        inherit userChrome;
        settings = merge (
          [
            (import ./config/preferences.nix)
            (import ./config/speed.nix)
          ]
          ++ nvidiaSettings
        );
        extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          clearurls
          #darkreader
          sponsorblock
          ublock-origin
          youtube-nonstop
          sidebery
          user-agent-string-switcher
        ];
        inherit search;
      };
    };
  };
}
