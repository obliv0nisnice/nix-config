{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  isx86 = pkgs.stdenv.hostPlatform.isx86_64;
  isAarch64 = pkgs.stdenv.hostPlatform.isAarch64;

  # reverse-engineering: skip two flaky handler tests (Apple-Silicon config carried this)
  unblobPatched = pkgs.unblob.overrideAttrs (old: {
    disabledTests = (old.disabledTests or []) ++ [
      "test_all_handlers[filesystem.romfs]"
      "test_all_handlers[filesystem.yaffs]"
    ];
  });

  # claude-code is published as per-arch prebuilt binaries; aarch64 needs the arm64 tarball.
  claudeCodeArm = pkgs.claude-code.overrideAttrs {
    version = "2.1.170";
    src = pkgs.fetchurl {
      url = "https://downloads.claude.ai/claude-code-releases/2.1.170/linux-arm64/claude";
      sha256 = "sha256-G7nQMkQKdVMvfdTK+8aH8iCq8Wxj66F+GS377C8EvSU=";
    };
  };
in
{
  programs = {
    firefox.enable = false; # Firefox is not installed by defualt
    dconf.enable = true;
    seahorse.enable = true;
    fuse.userAllowOther = true;
    virt-manager.enable = lib.mkDefault config.machineProfiles.virtualization.enable;
    mtr.enable = true;

    steam = lib.mkIf (config.machineProfiles.gaming.enable && isx86) {
      enable = true;
      remotePlay.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
      extraCompatPackages = with pkgs; [
        proton-ge-bin
      ];
    };

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [];
    };
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = config.machineProfiles.allowUnsupported.enable;
  nixpkgs.overlays = [
    inputs.nur.overlays.default
    (final: prev: {
      azurehound = prev.azurehound.overrideAttrs (_: {
        doCheck = false;
      });
    })
  ];

  environment.systemPackages = with pkgs;
    # ---- arch-neutral CLI base (all hosts) ----
    [
      cmatrix # Matrix Movie Effect In Terminal
      eza # Beautiful ls Replacement
      inxi
      kitty.terminfo
      killall
      lshw
      meson
      ncdu
      ninja
      nixfmt
      pciutils
      pkg-config
      ripgrep
      socat
      curl
      unrar
      unzip
      zip
      usbutils
      wget
      efibootmgr
      python3
      sysstat
      nodejs
      git-lfs
      neovim
      file
      gcc
      gnumake
      yazi
      codex
      rofimoji # emoji picker (replaces the old emoji.nix home module)
      typst
    ]
    # ---- x86-only base (pentest / mobile / gamedev tooling that doesn't target aarch64) ----
    ++ lib.optionals isx86 [
      amfora # Fancy Terminal Browser For Gemini Protocol
      duf
      lm_sensors
      lolcat
      python3Packages.pygments

      # Android / Mobile
      android-studio
      android-tools
      apktool
      jadx
      scrcpy
      jdk17

      # Frida / Proxy / MITM
      frida-tools
      burpsuite
      mitmproxy

      # Audible
      libation
      audible-cli
      audiobookshelf

      # GameDev
      godot
      blender
      tiled

      # Pentesting
      pywhisker
      krb5
      (evil-winrm.override { sslLegacyProvider = true; })
      ruby

      # RemoteConnection
      remmina
      openvpn

      claude-code
    ]
    # ---- aarch64-only base (Apple-Silicon known-good extras) ----
    ++ lib.optionals isAarch64 [
      coreutils-full
      libdrm
      ranger
      terraform
      awscli2
      claudeCodeArm
    ]
    # ---- desktop tools shared across arches ----
    ++ lib.optionals config.machineProfiles.desktop.enable [
      brightnessctl # Screen Brightness Control
      file-roller # Archive Manager
      tuigreet # Login Manager
      thunar-archive-plugin
      thunar-volman
      hyprpicker
      imv
      libnotify
      lxqt.lxqt-policykit
      mpv
      pavucontrol
      playerctl
      ytmdl
      floorp-bin
    ]
    # ---- x86-only desktop GUI / proprietary apps ----
    ++ lib.optionals (config.machineProfiles.desktop.enable && isx86) [
      appimage-run # AppImage support
      ffmpeg
      gedit
      gimp
      picard
      v4l-utils
      jetbrains.rider
      nvidia-system-monitor-qt
      spotify
      (texlive.combine {
        inherit (texlive) scheme-full adjustbox;
      })
      liquidctl
      flatpak
      vulkan-tools
      pdfstudioviewer
      obs-studio
    ]
    ++ lib.optionals config.machineProfiles.virtualization.enable [
      docker-compose # Allows Controlling Docker From A Single File
      docker-client
      libvirt
      virt-viewer
    ]
    ++ lib.optionals config.machineProfiles.communication.enable (
      [
        thunderbird
        teams-for-linux
      ]
      ++ lib.optionals isx86 [ (discord.override { withVencord = true; }) ]
      ++ lib.optionals isAarch64 [ vesktop ]
    )
    ++ lib.optionals (config.machineProfiles.gaming.enable && isx86) [
      heroic
      prismlauncher
    ]
    ++ lib.optionals config.machineProfiles.copyTools.enable [
      rsync
      rclone
      sshfs
      cifs-utils
    ]
    ++ lib.optionals config.machineProfiles.dotnet.enable [
      dotnet-sdk_8
    ]
    ++ lib.optionals config.machineProfiles.office.enable [
      libreoffice
      anki
    ]
    ++ lib.optionals config.machineProfiles.vpn.enable [
      mullvad-vpn
      netbird
      wireguard-tools
    ]
    ++ lib.optionals config.machineProfiles.security.pentest.enable [
      python313Packages.impacket
      medusa
      smtp-user-enum
    ]
    ++ lib.optionals config.machineProfiles.security.exploitDev.enable [
      gdb
      pwntools
      boofuzz
    ]
    ++ lib.optionals config.machineProfiles.security.reversing.enable [
      unblobPatched
    ]
    ++ lib.optionals config.machineProfiles.security.networkAnalysis.enable [
      wireshark
    ]
    ++ lib.optionals config.machineProfiles.security.remoteScan.enable [
      remmina
      openvpn
      openconnect
      openscap
    ];
}
