{ config, pkgs, ... }:

let
  myDotnetApp = import /home/jakob/github/projects/HomeDepot/Backend {};
in
{
  systemd.services.your-backend = {
    description = "HomeDepot .NET Backend Service";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart = "${myDotnetApp}/bin/HomeDepotBackend";
      Restart = "always";
    };
  };

  environment.systemPackages = [ myDotnetApp pkgs.dotnetPackages.sdk_6 ];
}

