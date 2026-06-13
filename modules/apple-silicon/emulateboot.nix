{
  config,
  lib,
  ...
}:

{
  config = lib.mkIf config.machineProfiles.apple.x86Emulation.enable {
    boot.binfmt.emulatedSystems = [ "x86_64-linux" ];
  };

}
