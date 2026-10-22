{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.machineProfiles.network.netbird;
in
{
  config = lib.mkIf cfg.enable {
    services.netbird.clients.wt0 = {
      # false = Daemon läuft, verbindet sich aber erst mit `netbird-wt0 up`.
      autoStart = cfg.autoConnect;

      # Automatically login to your Netbird network with a setup key
      # This is mostly useful for server computers.
      login = {
        enable = false;

        # Path to a file containing the setup key for your peer
        # NOTE: if your setup key is reusable, make sure it is not copied to the Nix store.
        setupKeyFile = "/path/to/your/setup-key";
      };

      # Port used to listen to wireguard connections
      port = 51821;

      logLevel = "error";

      # Set this to true if you want the GUI client
      ui.enable = false;

      # This opens ports required for direct connection without a relay
      openFirewall = true;

      # This opens necessary firewall ports in the Netbird client's network interface
      openInternalFirewall = true;
    };

    environment.systemPackages = [ pkgs.netbird ];
  };
}
