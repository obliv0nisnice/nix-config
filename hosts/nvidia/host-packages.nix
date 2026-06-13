{ pkgs, ... }:
{
  # Host-specific packages only. Feature toggles live in ./variables.nix
  # (profiles / customConf) and are bridged into the option system.
  environment.systemPackages = with pkgs; [ ];

  programs.qylock.lockTheme = "pixel-hollowknight";
}
