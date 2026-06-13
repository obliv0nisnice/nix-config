{
  # https://github.com/yokoffing/Betterfox
  "content.notify.interval" = 100000;
  "gfx.canvas.accelerated.cache-items" = 4096;
  "gfx.canvas.accelerated.cache-size" = 512;
  "gfx.content.skia-font-cache-size" = 20;
  "browser.cache.jsbc_compression_level" = 3;
  "browser.cache.disk.enable" = false;
  "browser.sessionhistory.max_total_viewers" = 4;
  "media.memory_cache_max_size" = 65536;
  "media.cache_readahead_limit" = 7200;
  "media.cache_resume_threshold" = 3600;
  "image.mem.decode_bytes_at_a_time" = 32768;
  "network.http.max-connections" = 1800;
  "network.http.max-persistent-connections-per-server" = 10;
  "network.http.max-urgent-start-excessive-connections-per-host" = 5;
  "network.http.pacing.requests.enabled" = false;
  "network.dnsCacheExpiration" = 3600;
  "network.ssl_tokens_cache_capacity" = 10240;
  # Disable Link Prefetching
  # Firefox prefetches the next site on some links, so the site is loaded even when
  # you never click.
  "network.dns.disablePrefetch" = true;
  "network.dns.disablePrefetchFromHTTPS" = true;
  "network.prefetch-next" = false;
  "network.predictor.enabled" = false;
  "network.predictor.enable-prefetch" = false;
  "network.http.speculative-parallel-limit" = 0;
  "browser.urlbar.speculativeConnect.enabled" = false;
  "browser.places.speculativeConnect.enabled" = false;
  "layout.css.grid-template-masonry-value.enabled" = true;
  "dom.enable_web_task_scheduling" = true;
}
