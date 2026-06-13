{
  # Disable firefox intro tabs on the first start
  # Disable the first run tabs with advertisements for the latest firefox features.
  "browser.startup.homepage_override.mstone" = "ignore";
  # Disable new tab page intro
  # Disable the intro to the newtab page on the first run
  "browser.newtabpage.introShown" = false;
  # Show bookmarks toolbar on new tab page
  "browser.toolbars.bookmarks.visibility" = "never";
  # Don't ask to save logins and passwords for websites
  "signon.rememberSignons" = false;
  # Pocket Reading List
  # No details
  "extensions.pocket.enabled" = false;
  "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
  # Disable Sponsored Top Sites
  # Firefox 83 introduced sponsored top sites
  # (https://support.mozilla.org/en-US/kb/sponsor-privacy), which are sponsored ads
  # displayed as suggestions in the URL bar.
  "services.sync.prefs.sync.browser.newtabpage.activity-stream.showSponsoredTopSite" = false;
  # Disable about:config warning.
  # No details
  "browser.aboutConfig.showWarning" = false;
  # Do not trim URLs in navigation bar
  # By default Firefox trims many URLs (hiding the http:// prefix and trailing slash
  # /).
  "browser.urlbar.trimURLs" = false;
  # Disable checking if Firefox is the default browser
  # No details
  "browser.shell.checkDefaultBrowser" = false;
  # Disable reset prompt.
  # When Firefox is not used for a while, it displays a prompt asking if the user
  # wants to reset the profile. (see Bug #955950
  # (https://bugzilla.mozilla.org/show_bug.cgi?id=955950)).
  "browser.disableResetPrompt" = true;
  # Disable Heartbeat Userrating
  # With Firefox 37, Mozilla integrated the Heartbeat
  # (https://wiki.mozilla.org/Advocacy/heartbeat) system to ask users from time to
  # time about their experience with Firefox.
  "browser.selfsupport.url" = "";
  # Content of the new tab page
  #
  "browser.newtabpage.enhanced" = false;
  # Disable the new tab page (blank page)
  "browser.newtabpage.enabled" = false;
  "browser.startup.homepage" = "about:blank";
  # Disable autoplay of <code>&lt;video&gt;</code> tags.
  # Per default, <code>&lt;video&gt;</code> tags are allowed to start automatically.
  # Note: When disabling autoplay, you will have to click pause and play again on
  # some video sites.
  "media.autoplay.enabled" = true;
  "media.autoplay.default" = 0;
  # Opens PDFs in the browser
  "browser.download.open_pdf_attachments_inline" = true;
  # Specifies the download directory.
  "browser.download.folderList" = 2;
  "browser.download.useDownloadDir" = false;
  "browser.download.dir" = "/tmp";
  # Restore previous session automatically
  "browser.startup.page" = 3;
  "extensions.activeThemeID" = "{5cd68d86-8324-4ab2-9e0d-3afcc60bee5f}";
  "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
  "browser.ctrlTab.sortByRecentlyUsed" = true;
  # Firefox 75+ remembers the last workspace it was opened on as part of its session management.
  # This is annoying, because I can have a blank workspace, open Firefox and
  # then have Firefox open on some other workspace
  "widget.disable-workspace-management" = true;
  # Automatically enable extensions, don't manually confirm if it should be enabled
  "extensions.autoDisableScopes" = 0;
}
