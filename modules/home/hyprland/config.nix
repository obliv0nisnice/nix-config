{
  host,
  username,
  config,
  machineProfiles,
  ...
}: 
let
  inherit
    (import ../../../hosts/${host}/variables.nix)
    browser
    terminal
    extraMonitorSettings
    workspaceSettings
    keyboardLayout
    ;
  batteryMode = machineProfiles.apple.batteryPerformance.enable;
in {
  wayland.windowManager.hyprland = {
    settings = {
      workspace = workspaceSettings;
      
      exec-once = [
        "systemctl --user import-environment WAYLAND_DISPLAY DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP"
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP"
        "nm-applet --indicator"
        "lxqt-policykit-agent"
        "pypr &"
        "awww-daemon"
        "sleep 1 && awww img $HOME/NixOS/wallpapers/Legend_of_Zelda.png"
        "hyprctl dispatch workspace 1"
      ];
      input = {
        kb_layout = "${keyboardLayout}";
        kb_options = [
          "grp:alt_caps_toggle"
          "caps:super"
        ];
        numlock_by_default = true;
        repeat_delay = 300;
        follow_mouse = 1;
        sensitivity = 0;
        touchpad = {
          natural_scroll = true;
          disable_while_typing = true;
          scroll_factor = 0.8;
        };
      };

        "$modifier" = "SUPER";
      
      general = {
        layout = "dwindle";
        gaps_in = 6;
        gaps_out = 8;
        border_size = 2;
        resize_on_border = true;
        "col.active_border" = "rgb(${config.lib.stylix.colors.base08}) rgb(${config.lib.stylix.colors.base0C}) 45deg";
        "col.inactive_border" = "rgb(${config.lib.stylix.colors.base01})";
      };

      misc = {
        middle_click_paste = false;
        layers_hog_keyboard_focus = true;
        initial_workspace_tracking = 0;
        mouse_move_enables_dpms = true;
        key_press_enables_dpms = false;
      };

      dwindle = {
        preserve_split = true;
      };

      decoration = {
        rounding = 10;
        blur = {
          enabled = true;
          size = if batteryMode then 3 else 5;
          passes = if batteryMode then 1 else 2;
          ignore_opacity = false;
          new_optimizations = true;
        };
        shadow = {
          enabled = !batteryMode;
          range = 4;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };
      };

      animations = {
        enabled = true;
        bezier = [
          "wind, 0.05, 0.9, 0.1, 1.05"
          "winIn, 0.1, 1.1, 0.1, 1.1"
          "winOut, 0.3, -0.3, 0, 1"
          "liner, 1, 1, 1, 1"
        ];
        animation = [
          "windows, 1, ${if batteryMode then "3" else "6"}, wind, slide"
          "windowsIn, 1, ${if batteryMode then "3" else "6"}, winIn, slide"
          "windowsOut, 1, ${if batteryMode then "3" else "5"}, winOut, slide"
          "windowsMove, 1, ${if batteryMode then "3" else "5"}, wind, slide"
          "border, 1, 1, liner"
          "fade, 1, ${if batteryMode then "4" else "10"}, default"
          "workspaces, 1, ${if batteryMode then "3" else "5"}, wind"
        ];
      };

      bind = [
        "$modifier,Return,exec,${terminal}"
        "$modifier,SPACE,exec,rofi-launcher"
        "$modifier SHIFT,W,exec,web-search"
        "$modifier ALT,W,exec,wallsetter"
        "$modifier SHIFT,N,exec,swaync-client -rs"
        "$modifier,W,exec,${browser}"
        "$modifier,E,exec,emopicker9000"
        "$modifier,S,exec,screenshootin"
        "$modifier,D,exec,vesktop"
        "$modifier,C,exec,hyprpicker -a"
        "$modifier,T,exec,pypr toggle term"
        "$modifier SHIFT,T,exec,pypr toggle thunar"
        "$modifier,M,exec,pavucontrol"
        "$modifier,Q,killactive,"
        "$modifier,L,exec,qylock-lock"
        "$modifier,P,exec,pypr toggle volume"
        "$modifier SHIFT,P,pseudo,"
        "$modifier SHIFT,I,layoutmsg,togglesplit"
        "$modifier,F,fullscreen,"
        "$modifier SHIFT,F,togglefloating,"
        "$modifier SHIFT,C,exit,"
        "$modifier SHIFT,left,movewindow,l"
        "$modifier SHIFT,right,movewindow,r"
        "$modifier SHIFT,up,movewindow,u"
        "$modifier SHIFT,down,movewindow,d"
        "$modifier SHIFT,h,movewindow,l"
        "$modifier SHIFT,l,movewindow,r"
        "$modifier SHIFT,k,movewindow,u"
        "$modifier SHIFT,j,movewindow,d"
        "$modifier,left,movefocus,l"
        "$modifier,right,movefocus,r"
        "$modifier,up,movefocus,u"
        "$modifier,down,movefocus,d"
        "$modifier,h,movefocus,l"
        "$modifier,l,movefocus,r"
        "$modifier,k,movefocus,u"
        "$modifier,j,movefocus,d"
        "$modifier,1,workspace,1"
        "$modifier,2,workspace,2"
        "$modifier,3,workspace,3"
        "$modifier,4,workspace,4"
        "$modifier,5,workspace,5"
        "$modifier,6,workspace,6"
        "$modifier,7,workspace,7"
        "$modifier,8,workspace,8"
        "$modifier,9,workspace,9"
        "$modifier,0,workspace,10"
        "$modifier,ssharp,workspace,11"
        "$modifier SHIFT,ssharp,movetoworkspace,11"
        "$modifier SHIFT,SPACE,movetoworkspace,special"
        #"$modifier,SPACE,togglespecialworkspace"
        "$modifier SHIFT,1,movetoworkspace,1"
        "$modifier SHIFT,2,movetoworkspace,2"
        "$modifier SHIFT,3,movetoworkspace,3"
        "$modifier SHIFT,4,movetoworkspace,4"
        "$modifier SHIFT,5,movetoworkspace,5"
        "$modifier SHIFT,6,movetoworkspace,6"
        "$modifier SHIFT,7,movetoworkspace,7"
        "$modifier SHIFT,8,movetoworkspace,8"
        "$modifier SHIFT,9,movetoworkspace,9"
        "$modifier SHIFT,0,movetoworkspace,10"
        "$modifier CONTROL,right,workspace,e+1"
        "$modifier CONTROL,left,workspace,e-1"
        "$modifier,mouse_down,workspace, e+1"
        "$modifier,mouse_up,workspace, e-1"
        "ALT,Tab,cyclenext"
        "ALT,Tab,bringactivetotop"
        ",XF86AudioRaiseVolume,exec,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ",XF86AudioLowerVolume,exec,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        " ,XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ",XF86AudioPlay, exec, playerctl play-pause"
        ",XF86AudioPause, exec, playerctl play-pause"
        ",XF86AudioNext, exec, playerctl next"
        ",XF86AudioPrev, exec, playerctl previous"
        ",XF86MonBrightnessDown,exec,brightnessctl set 5%-"
        ",XF86MonBrightnessUp,exec,brightnessctl set +5%"
      ];

      bindm = [
        "$modifier, mouse:272, movewindow"
        "$modifier, mouse:273, resizewindow"
      ];

      




windowrule = [
  "opacity 0.85, match:class discord, match:fullscreen 0"
  "tag file-manager 1, match:class ^([Tt]hunar|org.gnome.Nautilus|[Pp]cmanfm-qt)$"
  "tag terminal 1, match:class ^(Alacritty|kitty|kitty-dropterm)$"

  "tag browser 1, match:class ^(Brave-browser(-beta|-dev|-unstable)?)$"
  "tag browser 1, match:class ^([Ff]irefox|org.mozilla.firefox|[Ff]irefox-esr)$"
  "tag browser 1, match:class ^([Tt]horium-browser|[Cc]achy-browser)$"

  "tag projects 1, match:class ^(codium|codium-url-handler|VSCodium)$"
  "tag projects 1, match:class ^(VSCode|code-url-handler)$"

  "tag im 1, match:class ^([Dd]iscord|[Ww]ebCord|[Vv]esktop)$"
  "tag im 1, match:class ^([Ff]erdium)$"
  "tag im 1, match:class ^([Ww]hatsapp-for-linux)$"
  "tag im 1, match:class ^(org.telegram.desktop|io.github.tdesktop_x64.TDesktop)$"
  "tag im 1, match:class ^(teams-for-linux)$"

  "tag settings 1, match:class ^(gnome-disks|wihotspot(-gui)?)$"
  "tag settings 1, match:class ^([Rr]ofi)$"
  "tag settings 1, match:class ^(file-roller|org.gnome.FileRoller)$"
  "tag settings 1, match:class ^(nm-applet|nm-connection-editor|blueman-manager)$"
  "tag settings 1, match:class ^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$"
  "tag settings 1, match:class ^(nwg-look|qt5ct|qt6ct|[Yy]ad)$"
  "tag settings 1, match:class ^(xdg-desktop-portal-gtk)$"

  "move 72% 7%, match:title ^(Picture-in-Picture)$"

  "center 1, match:class ^([Ff]erdium)$"
  "center 1, match:class ^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$"
  "center 1, match:class ^([Tt]hunar)$, match:title negative (.*[Tt]hunar.*)"
  "center 1, match:title ^(Authentication Required)$"

  "float 1, match:tag settings.*"
  "float 1, match:class ^([Ff]erdium)$"
  "float 1, match:title ^(Picture-in-Picture)$"
  "float 1, match:class ^(mpv|com.github.rafostar.Clapper)$"
  "float 1, match:title ^(Authentication Required)$"
  "float 1, match:class ^(codium|codium-url-handler|VSCodium)$, match:title negative (.*codium.*|.*VSCodium.*)"
  "float 1, match:class ^(com.heroicgameslauncher.hgl)$, match:title negative (Heroic Games Launcher)"
  "float 1, match:class ^([Ss]team)$, match:title negative ^([Ss]team)$"
  "float 1, match:class ^([Tt]hunar)$, match:title negative (.*[Tt]hunar.*)"

  "float 1, match:title ^(Add Folder to Workspace)$"
  "float 1, match:title ^(Open Files)$"
  "float 1, match:title (wants to save)"

  "size 70% 60%, match:title ^(Open Files)$"
  "size 70% 60%, match:title ^(Add Folder to Workspace)$"
  "size 70% 70%, match:tag settings.*"
  "size 60% 70%, match:class ^([Ff]erdium)$"

  "opacity 1.0 1.0, match:tag browser.*"
  "opacity 0.9 0.8, match:tag projects.*"
  "opacity 0.94 0.86, match:tag im.*"
  "opacity 0.9 0.8, match:tag file-manager.*"
  "opacity 0.8 0.7, match:tag terminal.*"
  "opacity 0.8 0.7, match:tag settings.*"
  "opacity 0.8 0.7, match:class ^(gedit|org.gnome.TextEditor|mousepad)$"
  "opacity 0.9 0.8, match:class ^(seahorse)$"
  "opacity 0.95 0.75, match:title ^(Picture-in-Picture)$"

  "pin 1, match:title ^(Picture-in-Picture)$"

  "no_blur 1, match:tag games.*"
  "fullscreen 1, match:tag games.*"
];

      env = [
        "NIXOS_OZONE_WL, 1"
        "NIXPKGS_ALLOW_UNFREE, 1"
        "XDG_CURRENT_DESKTOP, Hyprland"
        "XDG_SESSION_TYPE, wayland"
        "XDG_SESSION_DESKTOP, Hyprland"
        "GDK_BACKEND, wayland, x11"
        "CLUTTER_BACKEND, wayland"
        "QT_QPA_PLATFORM=wayland;xcb"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION, 1"
        "QT_AUTO_SCREEN_SCALE_FACTOR, 1"
        #       "SDL_VIDEODRIVER, x11"
        "MOZ_ENABLE_WAYLAND, 1"
      ];
    };

    extraConfig = extraMonitorSettings;
  };
}
