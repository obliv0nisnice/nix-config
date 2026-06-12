{
  config,
  lib,
  ...
}:
let
  enable = config.services.k3s.enable;
in
{
  services.k3s.enable = lib.mkDefault false;

  services.k3s.role = lib.mkIf enable "server";
  services.k3s.extraFlags = lib.mkIf enable (toString [
    # "--debug" # Optionally add additional args to k3s
  ]);

  networking.firewall.allowedTCPPorts = lib.mkIf enable [
    6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
    # 2379 # k3s, etcd clients: required if using a "High Availability Embedded etcd" configuration
    # 2380 # k3s, etcd peers: required if using a "High Availability Embedded etcd" configuration
  ];
  networking.firewall.allowedUDPPorts = lib.mkIf enable [
    # 8472 # k3s, flannel: required if using multi-node for inter-node networking
  ];
}
