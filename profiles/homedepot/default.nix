{...}: {
  imports = [
    ../_common.nix
    ../../modules/server
  ];

  drivers.nvidia.enable = true;
}
