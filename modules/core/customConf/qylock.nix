{ lib, pkgs, config, ... }:
let
  cfg = config.programs.qylock;

  src = pkgs.fetchFromGitHub {
    owner = "Darkkal44";
    repo = "qylock";
    hash = "sha256-dIE85T8Dm2/yLcCWtjTQjMhc30N/mTwx5M+CZc23dOM=";
    rev = "d56bf3b51dfbd9d8f4c713044db7461d84ba2009";
  };

  lockTheme = pkgs.stdenv.mkDerivation {
    name = "qylock-theme-${cfg.lockTheme}";
    inherit src;
    installPhase = ''
      mkdir -p $out/share/sddm/themes/${cfg.lockTheme}
      cp -r themes/${cfg.lockTheme}/* $out/share/sddm/themes/${cfg.lockTheme}

      mkdir -p $out/lib/quickshell-lockscreen
      cp quickshell-lockscreen/lock_shell.qml $out/lib/quickshell-lockscreen/lock_shell.qml
      cp -r --no-preserve=mode,ownership \
        quickshell-lockscreen/shim $out/lib/quickshell-lockscreen/shim
      cp -r --no-preserve=mode,ownership \
        quickshell-lockscreen/imports $out/lib/quickshell-lockscreen/imports
      ln -s $out/share/sddm/themes $out/lib/quickshell-lockscreen/themes_link
    '';
  };

  lock = pkgs.writeShellScriptBin "qylock-lock" ''
    if pgrep -x quickshell > /dev/null; then
      exit 0
    fi

    export QT_PLUGIN_PATH="${pkgs.kdePackages.qtmultimedia}/lib/qt-6/plugins''${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}"
    export GST_PLUGIN_SYSTEM_PATH_1_0="${pkgs.gst_all_1.gstreamer}/lib/gstreamer-1.0:${pkgs.gst_all_1.gst-plugins-base}/lib/gstreamer-1.0:${pkgs.gst_all_1.gst-plugins-good}/lib/gstreamer-1.0:${pkgs.gst_all_1.gst-plugins-bad}/lib/gstreamer-1.0"
    export QML_IMPORT_PATH="${lockTheme}/lib/quickshell-lockscreen/imports:${pkgs.qt6.qtmultimedia}/lib/qt-6/qml:${pkgs.kdePackages.qt5compat}/lib/qt-6/qml''${QML_IMPORT_PATH:+:$QML_IMPORT_PATH}"
    export QML2_IMPORT_PATH="$QML_IMPORT_PATH"
    export QML_XHR_ALLOW_FILE_READ=1
    export QS_PAM_SERVICE=qylock
    export QS_THEME="${cfg.lockTheme}"
    export QS_THEME_PATH="${lockTheme}/share/sddm/themes/${cfg.lockTheme}"
    export WAYLAND_DISPLAY="''${WAYLAND_DISPLAY:-wayland-1}"
    export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    export XDG_SESSION_TYPE="wayland"

    cd ${lockTheme}/lib/quickshell-lockscreen
    exec ${pkgs.quickshell}/bin/quickshell -p lock_shell.qml "$@"
  '';

  package = pkgs.stdenv.mkDerivation {
    name = "qylock";
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      ln -s ${lock}/bin/qylock-lock $out/bin/qylock-lock
    '';
  };
in
{
  options.programs.qylock = {
    enable = lib.mkEnableOption "qylock lockscreen";

    lockTheme = lib.mkOption {
      type = lib.types.str;
      default = "nier-automata";
      description = "The qylock theme to use for the lockscreen.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ package ];

    security.pam.services.qylock = {
      text = ''
        auth      include   login
        account   include   login
        password  include   login
        session   include   login
      '';
    };
  };
}
