{ config, lib, inputs, ... }: {
  imports = [
    ./NASmount.nix
    ./qylock.nix
  ];

  # Mac-style lockscreen (qylock-lock is invoked by the hyprland/hypridle home
  # modules). Toggle: machineProfiles.desktop.lockscreen in variables.nix.
  programs.qylock.enable = lib.mkDefault (config.machineProfiles.desktop.enable && config.machineProfiles.desktop.lockscreen.enable);
}
