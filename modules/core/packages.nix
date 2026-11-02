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
in
{
  programs = {
    firefox.enable = false; # Firefox is not installed by defualt
    dconf.enable = true;
    seahorse.enable = true;
    fuse.userAllowOther = true;
    virt-manager.enable = lib.mkDefault config.machineProfiles.virtualization.enable;
    mtr.enable = true;

    steam = lib.mkIf (config.machineProfiles.desktop.gaming.enable && isx86) {
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
  nixpkgs.config.allowUnsupportedSystem = config.machineProfiles.apple.allowUnsupported.enable;
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
      rofimoji # emoji picker (replaces the old emoji.nix home module)
      typst
      yazi
      claude-code
      
    ]
    # ---- x86-only CLI base ----
    ++ lib.optionals isx86 [
      amfora # Fancy Terminal Browser For Gemini Protocol
      duf
      lm_sensors
      lolcat
      python3Packages.pygments
    ]
    ++ lib.optionals (config.machineProfiles.dev.mobile.enable && isx86) [
      android-studio
      android-tools
      apktool
      jadx
      scrcpy
      jdk17
    ]
    ++ lib.optionals (config.machineProfiles.dev.gamedev.enable && isx86) [
      godot
      blender
      tiled
    ]

    # ---- aarch64-only base (Apple-Silicon known-good extras) ----
    ++ lib.optionals isAarch64 [
      coreutils-full
      libdrm
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
    ]
    # ---- x86-only desktop GUI / proprietary apps ----
    ++ lib.optionals (config.machineProfiles.desktop.enable && isx86) [
      appimage-run # AppImage support
      ffmpeg
      gedit
      gimp
      v4l-utils
      nvidia-system-monitor-qt
      liquidctl
      flatpak
      vulkan-tools
      obs-studio
    ]
    ++ lib.optionals (config.machineProfiles.desktop.enable && config.machineProfiles.desktop.entertainment.enable) (
      [ ytmdl ]
      ++ lib.optionals isx86 [
        picard
        spotify
      ]
    )
    ++ lib.optionals config.machineProfiles.virtualization.enable [
      docker-compose # Allows Controlling Docker From A Single File
      docker-client
      libvirt
      virt-viewer
    ]
    ++ lib.optionals config.machineProfiles.desktop.communication.enable (
      [
        thunderbird
        teams-for-linux
      ]

      ++ lib.optionals (config.machineProfiles.desktop.discord.enable && isx86) [ (discord.override { withVencord = true; }) ]
      
      ++ lib.optionals (config.machineProfiles.desktop.discord.enable && isAarch64) [ vesktop ]
    )

    ++ lib.optionals (config.machineProfiles.desktop.gaming.enable && isx86) [
      heroic
      prismlauncher
    ]
    
    ++ lib.optionals config.machineProfiles.network.copyTools.enable [
      rsync
      rclone
      sshfs
      cifs-utils
    ]
    ++ lib.optionals config.machineProfiles.dev.dotnet.enable [
      dotnet-sdk_8
    ]
    ++ lib.optionals config.machineProfiles.desktop.office.enable [
      libreoffice
      anki
    ]
    ++ lib.optionals config.machineProfiles.network.vpn.enable [
      mullvad-vpn
      wireguard-tools
    ]
    ++ lib.optionals config.machineProfiles.security.pentest.enable (
      [
        python313Packages.impacket
        medusa
        smtp-user-enum
      ]
      ++ lib.optionals isx86 [
        pywhisker
        krb5
        (evil-winrm.override { sslLegacyProvider = true; })
        ruby
      ]
    )
    ++ lib.optionals config.machineProfiles.security.exploitDev.enable [
      gdb
      pwntools
      boofuzz
    ]
    ++ lib.optionals config.machineProfiles.security.reversing.enable [
      #unblobPatched
      ghidra
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
