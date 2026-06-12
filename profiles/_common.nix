{
  inputs,
  host,
  lib,
  ...
}: {
  imports = [
    ../hosts/${host}
    ../modules/drivers
    ../modules/core
    inputs.minegrub-world-sel-theme.nixosModules.default
  ];

  drivers.amdgpu.enable = lib.mkDefault false;
  drivers.nvidia.enable = lib.mkDefault false;
  drivers.nvidia-prime.enable = lib.mkDefault false;
  drivers.intel.enable = lib.mkDefault false;
  vm.guest-services.enable = lib.mkDefault false;
}
