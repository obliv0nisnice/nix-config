{
  pkgs,
  config,
  lib,
  options,
  ...
}: let
  hasMinegrubModule = options.boot.loader.grub ? minegrub-world-sel;
  minegrubTheme = pkgs.stdenv.mkDerivation {
    pname = "minegrub-world-sel-theme";
    version = "1.0";
    src = pkgs.fetchFromGitHub {
      owner = "Lxtharia";
      repo = "minegrub-world-sel-theme";
      rev = "main";
      hash = "sha256-gBlP4aQQ0f3L6S1gWbidbflnp0p5hsJ8qmbyArZ8LO4=";
    };

    unpackPhase = ":";
    installPhase = ''
      mkdir -p $out/grub/theme
      cp -r $src/minegrub-world-selection/* $out/grub/theme
    '';
  };
in {
  # x86-only boot stack (GRUB theme, latest kernel, aarch64 emulation, AppImage).
  # On aarch64/Asahi the kernel + bootloader come from apple-silicon-support and
  # modules/apple-silicon, so this whole block stays inert there.
  boot = lib.mkIf pkgs.stdenv.hostPlatform.isx86_64 {
    binfmt.emulatedSystems = [ "aarch64-linux" ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = lib.optionals config.machineProfiles.desktop.enable ["v4l2loopback"];
    extraModulePackages = lib.optionals config.machineProfiles.desktop.enable [config.boot.kernelPackages.v4l2loopback];
    kernel.sysctl = {"vm.max_map_count" = 2147483642;};

    loader = {
      grub = {
        enable = true;
        efiSupport = true;
        device = "nodev"; # required for EFI systems
        useOSProber = true;

        # Theme aus Nix Store
        theme = lib.mkIf config.machineProfiles.desktop.enable (lib.mkForce "${minegrubTheme}/grub/theme");

        # Minegrub Theme Integration
      } // lib.optionalAttrs hasMinegrubModule {
        minegrub-world-sel = {
          enable = config.machineProfiles.desktop.enable;
          customIcons = [
            {
              name = "nixos";
              lineTop = "NixOS (23/11/2023, 23:03)";
              lineBottom = "Survival Mode, No Cheats, Version: 23.11";
              imgName = "nixos";
            }
          ];
        };
      };

      efi.canTouchEfiVariables = true;
    };

    # AppImage Support
    binfmt.registrations.appimage = lib.mkIf config.machineProfiles.desktop.enable {
      wrapInterpreterInShell = false;
      interpreter = "${pkgs.appimage-run}/bin/appimage-run";
      recognitionType = "magic";
      offset = 0;
      mask = ''\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff'';
      magicOrExtension = ''\x7fELF....AI\x02'';
    };

    plymouth.enable = config.machineProfiles.desktop.enable;
  };
}
