{
  # Fake another Useragent
  # Using a popular useragent string
  # (https://techblog.willshouse.com/2012/01/03/most-common-user-agents/) avoids
  # attracting attention i.e. with an Iceweasel UA. (keep blank to use the default)

  # Block Cookies
  # Block 3rd-Party cookies or even all cookies.
  "network.cookie.cookieBehavior" = 5;
  # Block Referer
  # Firefox tells a website, from which site you're coming (the so called RefControl
  # (http://kb.mozillazine.org/Network.http.sendRefererHeader">referer</a>). You can
  # find more detailed settings in this <a
  # href="http://www.ghacks.net/2015/01/22/improve-online-privacy-by-controlling-referrer-information/">ghacks
  # article</a> or install the <a
  # href="https://addons.mozilla.org/firefox/addon/refcontrol/) extension for per
  # domain settings.
  # Disabled because it breaks youtube embeds
  "network.http.referer.spoofSource" = false;
  # Disable DOM storage
  # Disables DOM storage, which enables so called "supercookies". Some modern sites
  # will not work (i.e. missing "save" functions).
  "dom.storage.enabled" = true;
  # Disable IndexedDB (breaks things)
  # abused for tracking (http://www.w3.org/TR/IndexedDB/">IndexedDB</a> is a way,
  # websites can store structured data. This can be <a
  # href="http://arstechnica.com/apple/2010/09/rldguid-tracking-cookies-in-safari-database-form/),
  # too. Disabling causes problems when sites depend on it like Tweetdeck or Reddit
  # and extensions that use it to store their data. Some users reported crashing
  # tabs when IndexedDB is disabled. Only disable it, when you know what you're
  # doing.
  "dom.indexedDB.enabled" = true;
  # Disable the Offline Cache.
  # Websites can store up to 500 MB of data in an offline cache
  # (http://kb.mozillazine.org/Browser.cache.offline.enable), to be able to run even
  # when there is no working internet connection. This could possibly be used to
  # store an user id.
  "browser.cache.offline.enable" = false;
  # Sessionstore Privacy
  # This preference controls when to store extra information about a session:
  # contents of forms, scrollbar positions, cookies, and POST data.
  "browser.sessionstore.privacy_level" = 2;
  # Link prefetching and speculative loading prefs live in speed.nix
  # Use a private container for new tab page thumbnails
  # Load the pages displayed on the new tab page in a private container when
  # creating thumbnails.
  "privacy.usercontext.about_newtab_segregation.enabled" = true;
  # Disable WebGL (override: enabled, to make those websites work.)
  # Disables the WebGL function, to prevent (ab)use the full power of the graphics
  # card (http://www.uniquemachine.org/">fingerprinting with WebGL</a>. Another
  # issue is, that websites can <a
  # href="https://isc.sans.edu/forums/diary/Time+to+disable+WebGL/10867). WebGL is
  # part of some fingerprinting scripts used in the wild. Some interactive websites
  # will not work, which are mostly games.
  "webgl.disabled" = false;
  # Override graphics card vendor and model strings in the WebGL API
  # Websites can read the graphics card vendor and model using a WebGL API. This
  # setting overrides both with " " without disabling WebGL.
  "webgl.renderer-string-override" = " ";
  "webgl.vendor-string-override" = " ";
  # Disable WebRTC (disabled)
  # Disables the WebRTC function, which gives away your local ips. Some addons like
  # uBlock origin provide settings to prevent WebRTC from exposing local ips without
  # disabling WebRTC.
  "media.peerconnection.enabled" = true;
  # Disable the clipboardevents.
  # Disable that websites can get notifications if you copy, paste, or cut something
  # from a web page, and it lets them know which part of the page had been selected.
  # Enabled as it is needed by some webapps I use.
  #"dom.event.clipboardevents.enabled" = false;
  "dom.event.clipboardevents.enabled" = true;
  # Disable Search Suggestions
  # Firefox suggests search terms in the search field. This will send everything
  # typed or pasted in the search field to the chosen search engine, even when you
  # did not press enter.
  "browser.search.suggest.enabled" = false;
  # Disable Search Keyword
  # When you mistype some url, Firefox starts a search even from urlbar. This
  # feature is useful for quick searching, but may harm your privacy, when it's
  # unintended.
  "keyword.enabled" = true;
  # Disable Fixup URLs
  # When you type "something" in the urlbar and press enter, Firefox tries
  # "something.com", if Fixup URLs is enabled.
  "browser.fixup.alternate.enabled" = true;
}
