{ ... }:

{
  zramSwap = {
    enable = true;
    algorithm = "zstd";    # beste Kompression/Speed Balance
    memoryPercent = 50;    # 8 GB zram aus 16 GB RAM → effektiv ~24 GB nutzbar
  };

  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 8192;            # 8 GB Disk-Swap als Fallback unter zram
  }];

  boot.kernel.sysctl = {
    "vm.swappiness"             = 150;
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
    "vm.page-cluster"           = 0;
  };

  systemd.oomd = {
    enable = true;
    enableRootSlice = true;
    enableUserSlices = true;
    enableSystemSlice = true;
  };
}
