# Enable the Secure Enclave (SEP) device-tree node so the sep.ko boot stub
# probes. Touch ID reverse-engineering, step 3 (~/Projects/MacFingerprint).
#
# Why a build-time kernel patch (not hardware.deviceTree.overlays / configfs):
#   - m1n1 loads the DTB directly from ${kernel}/dtbs/apple/, so NixOS
#     hardware.deviceTree.overlays has no effect on this platform.
#   - CONFIG_OF_CONFIGFS (runtime configfs DT overlays) does not exist in the
#     asahi/mainline kernel.
# So we patch the DTS: in t602x-die0.dtsi the sep node goes disabled -> okay.
# boot.kernelPatches is forwarded into linux-asahi by apple-silicon-support.
{ ... }:
{
  boot.kernelPatches = [
    {
      name = "enable-sep-node";
      patch = ./sep-enable.patch;
    }
    {
      # Debug: log SEP endpoints during EP_DISCOVER (Phase 2 prep, confirm SBIO 0x08).
      name = "sep-discover-log";
      patch = ./sep-discover-log.patch;
    }
  ];
}
