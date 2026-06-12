{
  config,
  lib,
  inputs,
  ...
}:
let
  secretsFile = ../../secrets/secrets.yaml;
  hasSecretsFile = builtins.pathExists secretsFile;
in
if !hasSecretsFile then {
  # No secrets file present — sops-nix stays out of the build,
  # consuming modules fall back to hard-coded defaults.
} else {
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops = {
    defaultSopsFile = secretsFile;
    defaultSopsFormat = "yaml";
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    secrets = lib.mkMerge [
      (lib.mkIf config.machineProfiles.sonarqube.enable {
        "sonarqube/env" = {
          owner = "root";
          mode = "0400";
        };
      })
      (lib.mkIf config.machineProfiles.dependencyTrack.enable {
        "dependency-track/env" = {
          owner = "root";
          mode = "0400";
        };
      })
      (lib.mkIf config.machineProfiles.homesuite.enable {
        "homesuite/env" = {
          owner = "homesuite";
          mode = "0400";
        };
      })
      (lib.mkIf config.machineProfiles.gitea.enable {
        "gitea/db-password" = {
          owner = "gitea";
          mode = "0400";
          path = "/etc/gitea/db-password";
        };
        "gitea/runner-token" = {
          owner = "root";
          mode = "0400";
          path = "/etc/gitea/runner-token";
        };
        "gitea/provisioner-token" = {
          owner = "root";
          mode = "0400";
        };
      })
      (lib.mkIf config.machineProfiles.stepCa.enable {
        "step-ca/intermediate-password" = {
          owner = "step-ca";
          mode = "0400";
        };
      })
    ];
  };

  services.homesuite.environmentFile = lib.mkIf
    config.machineProfiles.homesuite.enable
    config.sops.secrets."homesuite/env".path;
}
