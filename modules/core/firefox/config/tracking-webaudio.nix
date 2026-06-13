{
  # Disable webaudio API
  # Disable webaudio API to prevent browser fingerprinting. See Mozilla Bug #1288359
  # (https://bugzilla.mozilla.org/show_bug.cgi?id=1288359). This can break web apps,
  # like Discord, which rely on the API.
  "dom.webaudio.enabled" = true;
}
