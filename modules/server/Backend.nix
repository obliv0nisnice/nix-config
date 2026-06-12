{ config, pkgs, ... }:

let

homeDepotBackend = pkgs.callPackage ../../Backend/API/default.nix { };

in


{


systemd.services.HomeDepotBackend = {
      enable = true;
      description = "Home Depot Backend Service";
      after = [ "network.target" ];

      serviceConfig = {
        ExecStart = "${homeDepotBackend}/bin/API";
        Restart = "always";
        RestartSec = "10";
        WorkingDirectory = "/var/lib/homeDepotBackend";
        User = "jakob";
        Group = "users";
        Environment = "ASPNETCORE_ENVIRONMENT=Production";
        DOTNET_ROOT= "${pkgs.dotnet-sdk_8}";
	StandardOutput = "journal";
        StandardError = "journal";
      };

      wantedBy = [ "multi-user.target" ];
    };
}
