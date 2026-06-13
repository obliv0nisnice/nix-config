{
  config,
  pkgs,
  ...
}:
{
  hardware = {
    sane = {
      enable = config.machineProfiles.desktop.printing.enable;
      extraBackends = [ pkgs.sane-airscan ];
      disabledDefaultBackends = [ "escl" ];
    };
    logitech.wireless.enable = false;
    logitech.wireless.enableGraphical = false;
    graphics.enable = true;
    enableRedistributableFirmware = true;
    keyboard.qmk.enable = true;
    bluetooth.enable = config.machineProfiles.desktop.bluetooth.enable;
    bluetooth.powerOnBoot = config.machineProfiles.desktop.bluetooth.enable;
  };
  # NB: local.hardware-clock.enable (from modules/drivers, x86-only) defaults to
  # false already, so it is not set here — keeps this module arch-portable for
  # the macbook host, which does not import modules/drivers.
}
