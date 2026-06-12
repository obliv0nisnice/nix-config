{
  config,
  lib,
  ...
}:

{
  config = lib.mkIf config.machineProfiles.virtualization.enable {
    virtualisation.libvirtd.enable = true;
    virtualisation.docker.enable = true;

    hardware.nvidia-container-toolkit.enable = false;
  };
}
