{
  config,
  lib,
  pkgs,
  username,
  host,
  ...
}: let
  inherit (import ../../hosts/${host}/variables.nix) keyboardLayout;
in {
  # Services to start
  services = {
    libinput.enable = config.machineProfiles.desktop.enable;
    fstrim.enable = true;
    gvfs.enable = config.machineProfiles.desktopIntegration.enable;
    openssh.enable = config.machineProfiles.remoteAccess.enable;
    flatpak.enable = config.machineProfiles.flatpak.enable;
    blueman.enable = config.machineProfiles.bluetooth.enable;

    xserver = {
      enable = false;
      xkb = {
        layout = "${keyboardLayout}";
        variant = "";
      };
    };
    greetd = lib.mkIf config.machineProfiles.desktop.enable {
      enable = true;
      settings = {
        default_session = {
          user = username;
          command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd start-hyprland"; # start Hyprland with a TUI login manager
        };
      };
    };
    smartd = {
      enable = false;
      autodetect = true;
    };
    printing = {
      enable = config.machineProfiles.printing.enable;
      drivers = [
        # pkgs.hplipWithPlugin
      ];
    };
    gnome.gnome-keyring.enable = config.machineProfiles.desktop.enable;
    avahi = {
      enable = config.machineProfiles.desktopIntegration.enable;
      nssmdns4 = true;
      openFirewall = true;
    };
    ipp-usb.enable = config.machineProfiles.printing.enable;
    syncthing = {
      enable = false;
      user = "${username}";
      dataDir = "/home/${username}";
      configDir = "/home/${username}/.config/syncthing";
    };
    pipewire = lib.mkIf config.machineProfiles.audio.enable {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    rpcbind.enable = config.machineProfiles.nfsServer.enable;
    nfs.server.enable = config.machineProfiles.nfsServer.enable;
  };

  systemd.services.flatpak-repo = lib.mkIf config.machineProfiles.flatpak.enable {
    wantedBy = ["multi-user.target"];
    path = [pkgs.flatpak];
    script = ''
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    '';
  };

  # Security / Polkit
  security = {
    rtkit.enable = config.machineProfiles.audio.enable;
  } // lib.optionalAttrs config.machineProfiles.desktop.enable {
    polkit.enable = true;
    polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (
          subject.isInGroup("users")
            && (
              action.id == "org.freedesktop.login1.reboot" ||
              action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
              action.id == "org.freedesktop.login1.power-off" ||
              action.id == "org.freedesktop.login1.power-off-multiple-sessions"
            )
          )
        {
          return polkit.Result.YES;
        }
      })
    '';
    pam.services.swaylock = {
      text = ''
        auth include login
      '';
    };
  };
}
