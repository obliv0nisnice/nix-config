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
    gvfs.enable = config.machineProfiles.desktop.desktopIntegration.enable;
    openssh.enable = config.machineProfiles.network.remoteAccess.enable;
    flatpak.enable = config.machineProfiles.desktop.flatpak.enable;
    blueman.enable = config.machineProfiles.desktop.bluetooth.enable;
    # Bis nixpkgs 26.05 transitiv reingezogen, in 26.11 nicht mehr -> explizit
    # aktivieren (u.a. fürs Waybar power-profiles-daemon-Widget).
    power-profiles-daemon.enable = config.machineProfiles.desktop.enable;

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
      enable = config.machineProfiles.desktop.printing.enable;
      drivers = [
        # pkgs.hplipWithPlugin
      ];
    };
    gnome.gnome-keyring.enable = config.machineProfiles.desktop.enable;
    avahi = {
      enable = config.machineProfiles.desktop.desktopIntegration.enable;
      nssmdns4 = true;
      openFirewall = true;
    };
    ipp-usb.enable = config.machineProfiles.desktop.printing.enable;
    syncthing = {
      enable = false;
      user = "${username}";
      dataDir = "/home/${username}";
      configDir = "/home/${username}/.config/syncthing";
    };
    pipewire = lib.mkIf config.machineProfiles.desktop.audio.enable {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    rpcbind.enable = config.machineProfiles.server.nfsServer.enable;
    nfs.server.enable = config.machineProfiles.server.nfsServer.enable;
  };

  systemd.services.flatpak-repo = lib.mkIf config.machineProfiles.desktop.flatpak.enable {
    wantedBy = ["multi-user.target"];
    # Braucht Netz/DNS. Nach network-online ordnen und Fehlschlag tolerieren, sonst
    # bricht jeder Rebuild/Boot ohne (sofortige) Auflösung ab. --if-not-exists ist
    # idempotent -> der nächste Boot mit Netz trägt das Remote nach.
    after = ["network-online.target"];
    wants = ["network-online.target"];
    path = [pkgs.flatpak];
    script = ''
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
    '';
  };

  # Security / Polkit
  security = {
    rtkit.enable = config.machineProfiles.desktop.audio.enable;
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
