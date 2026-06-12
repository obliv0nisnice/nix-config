{ config, lib, inputs, ... }: {
  imports = [
    ./NASmount.nix
    ./qylock.nix
  ];

  # Mac-style lockscreen (qylock-lock is invoked by the hyprland/hypridle home
  # modules). Enabled on every desktop host by default; override per host.
  programs.qylock.enable = lib.mkDefault config.machineProfiles.desktop.enable;
}
