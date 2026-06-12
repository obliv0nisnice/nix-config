{...}: {
  imports = [
    ./gitea.nix
    ./sonarqube.nix
    ./dependency-track.nix
    ./security-pipeline-provisioner.nix
  ];
}
