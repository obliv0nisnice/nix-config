{
  lib,
  pkgs,
  host,
  username,
  config,
  machineProfiles,
  ...
}:
let
  vars = import ../../../hosts/${host}/variables.nix;
  inherit
    (vars)
    browser
    terminal
    discordClient
    workspaceSettings
    keyboardLayout
    ;
  # Optionaler Roh-Lua-Escape-Hatch (darf in variables.nix fehlen).
  # Wird unverändert ans Ende von hyprland.lua gehängt.
  extraMonitorSettings = vars.extraMonitorSettings or "";
  batteryMode = machineProfiles.apple.batteryPerformance.enable;

  # Kleiner Parser für die alten hyprlang-Strings aus variables.nix, damit die
  # Hosts nicht umgestellt werden müssen. Attrsets werden direkt durchgereicht.
  splitTrim = sep: s: map lib.trim (lib.splitString sep s);
  parseValue = v:
    if v == "true" then true
    else if v == "false" then false
    else v;

  # "DP-1,2560x1440@144,0x0,1[,transform,3,...]" -> { output; mode; position; scale; ... }
  parseMonitor = m:
    if lib.isAttrs m then m
    else
      let
        parts = splitTrim "," m;
        at = i: default: if builtins.length parts > i then builtins.elemAt parts i else default;
        extra = lib.drop 4 parts;
        extraPairs = lib.listToAttrs (lib.genList (i:
          lib.nameValuePair (builtins.elemAt extra (2 * i)) (
            let v = builtins.elemAt extra (2 * i + 1);
            in if builtins.match "[0-9]+" v != null then lib.toInt v else parseValue v
          )) (builtins.length extra / 2));
      in
        { output = at 0 ""; mode = at 1 "preferred"; position = at 2 "auto"; scale = at 3 "auto"; }
        // extraPairs;

  # "1, monitor:DP-2, default:true" -> { workspace = "1"; monitor = "DP-2"; default = true; }
  parseWorkspace = w:
    if lib.isAttrs w then w
    else
      let
        parts = splitTrim "," w;
        kv = p:
          let
            m = builtins.match "([^:]*):(.*)" p;
          in lib.nameValuePair (builtins.elemAt m 0) (parseValue (builtins.elemAt m 1));
      in
        { workspace = lib.head parts; } // lib.listToAttrs (map kv (lib.tail parts));

  # Monitore: Hosts können in variables.nix `monitors` als Liste von
  # Hyprland-Monitorstrings (z.B. "DP-1,2560x1440@144,0x0,1") oder als
  # Attrsets im Lua-Format ({ output = "DP-1"; mode = "..."; ... }) setzen.
  # Ist nichts gesetzt, greift der automatische Default (preferred/auto/auto).
  monitors = vars.monitors or [ ];
  monitorSetting =
    if monitors != [ ]
    then map parseMonitor monitors
    else if extraMonitorSettings != ""
    then [ ]
    else [ (parseMonitor ",preferred,auto,auto") ];

  # Wallpaper: `wallpaper` = globaler Default für alle Bildschirme.
  # `wallpapers` = optionales Attrset { "<output>" = "<datei>"; } für ein
  # eigenes Wallpaper pro Bildschirm. Der Default wird zuerst auf alle Outputs
  # gelegt, danach überschreiben die Einträge aus `wallpapers` einzelne Monitore.
  wallpaper = vars.wallpaper or "Legend_of_Zelda.png";
  wallpapers = vars.wallpapers or { };
  wpPath = file: "$HOME/nix-config/wallpapers/${file}";
  awwwBin = "${pkgs.awww}/bin/awww";
  # `|| true` bei den per-Monitor-Overrides: nicht angeschlossene Outputs
  # (z.B. externe Displays im Nicht-Dock-Betrieb) sollen den Service nicht failen.
  wallpaperApply =
    [ "${awwwBin} img ${wpPath wallpaper}" ]
    ++ lib.mapAttrsToList (out: file: "${awwwBin} img --outputs ${out} ${wpPath file} || true") wallpapers;
  # Skript wird als systemd-User-Service ausgeführt: beim Login über die
  # hyprland-session.target UND bei jedem Rebuild (der Store-Pfad ändert sich mit
  # dem Wallpaper, sd-switch startet den Service dann neu).
  setWallpaperScript = pkgs.writeShellScript "set-wallpaper" ''
    # Auf den awww-Daemon warten (beim Login startet er evtl. noch).
    for _ in $(seq 1 50); do
      ${awwwBin} query >/dev/null 2>&1 && break
      sleep 0.2
    done
    ${lib.concatStringsSep "\n    " wallpaperApply}
  '';

  speed = battery: normal: if batteryMode then battery else normal;
  colors = config.lib.stylix.colors;

  # Größen/Positionen relativ zum Monitor (ersetzt die alten "70% 60%"-Angaben).
  pct = w: h: [ "monitor_w*${w}" "monitor_h*${h}" ];

  settingsClasses = "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$";
in {
  wayland.windowManager.hyprland = {
    # Mit configType = "lua" wird jedes Attribut zu einem hl.<name>(...)-Aufruf
    # (Listen => ein Aufruf pro Element). Keybinds & Autostart sind echter
    # Lua-Code und stehen daher unten in extraConfig.
    settings = {
      monitor = monitorSetting;
      workspace_rule = map parseWorkspace workspaceSettings;

      env = map (e: { _args = e; }) [
        [ "NIXOS_OZONE_WL" "1" ]
        [ "NIXPKGS_ALLOW_UNFREE" "1" ]
        [ "XDG_CURRENT_DESKTOP" "Hyprland" ]
        [ "XDG_SESSION_TYPE" "wayland" ]
        [ "XDG_SESSION_DESKTOP" "Hyprland" ]
        [ "GDK_BACKEND" "wayland,x11" ]
        [ "CLUTTER_BACKEND" "wayland" ]
        [ "QT_QPA_PLATFORM" "wayland;xcb" ]
        [ "QT_WAYLAND_DISABLE_WINDOWDECORATION" "1" ]
        [ "QT_AUTO_SCREEN_SCALE_FACTOR" "1" ]
        # [ "SDL_VIDEODRIVER" "x11" ]
        [ "MOZ_ENABLE_WAYLAND" "1" ]
      ];

      config = {
        input = {
          kb_layout = keyboardLayout;
          kb_options = "grp:alt_caps_toggle,caps:super";
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

        general = {
          layout = "dwindle";
          gaps_in = 6;
          gaps_out = 8;
          border_size = 2;
          resize_on_border = true;
          col = {
            active_border = {
              colors = [ "rgb(${colors.base08})" "rgb(${colors.base0C})" ];
              angle = 45;
            };
            inactive_border = "rgb(${colors.base01})";
          };
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
            size = speed 3 5;
            passes = speed 1 2;
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
        };
      };

      # `curve` steht in importantPrefixes und wird daher vor `animation` gerendert.
      curve = map (c: { _args = [ c.name { type = "bezier"; points = c.points; } ]; }) [
        { name = "wind"; points = [ [ 0.05 0.9 ] [ 0.1 1.05 ] ]; }
        { name = "winIn"; points = [ [ 0.1 1.1 ] [ 0.1 1.1 ] ]; }
        { name = "winOut"; points = [ [ 0.3 (-0.3) ] [ 0 1 ] ]; }
        { name = "liner"; points = [ [ 1 1 ] [ 1 1 ] ]; }
      ];

      animation = [
        { leaf = "windows"; enabled = true; speed = speed 3 6; bezier = "wind"; style = "slide"; }
        { leaf = "windowsIn"; enabled = true; speed = speed 3 6; bezier = "winIn"; style = "slide"; }
        { leaf = "windowsOut"; enabled = true; speed = speed 3 5; bezier = "winOut"; style = "slide"; }
        { leaf = "windowsMove"; enabled = true; speed = speed 3 5; bezier = "wind"; style = "slide"; }
        { leaf = "border"; enabled = true; speed = 1; bezier = "liner"; }
        { leaf = "fade"; enabled = true; speed = speed 4 10; bezier = "default"; }
        { leaf = "workspaces"; enabled = true; speed = speed 3 5; bezier = "wind"; }
      ];

      # Reihenfolge ist relevant: bei Konflikten gewinnt die letzte passende Regel.
      window_rule = [
        # Maximize-Anfragen der Apps ignorieren, sonst wird das erste Fenster
        # eines Workspaces maximiert und neue Fenster kacheln nicht daneben.
        { name = "suppress-maximize-events"; match.class = ".*"; suppress_event = "maximize"; }
        { match = { class = "discord"; fullscreen = false; }; opacity = "0.85"; }

        # Tags
        { match.class = "^([Tt]hunar|org.gnome.Nautilus|[Pp]cmanfm-qt)$"; tag = "+file-manager"; }
        { match.class = "^(Alacritty|kitty|kitty-dropterm)$"; tag = "+terminal"; }

        { match.class = "^(Brave-browser(-beta|-dev|-unstable)?)$"; tag = "+browser"; }
        { match.class = "^([Ff]irefox|org.mozilla.firefox|[Ff]irefox-esr)$"; tag = "+browser"; }
        { match.class = "^([Tt]horium-browser|[Cc]achy-browser)$"; tag = "+browser"; }

        { match.class = "^(codium|codium-url-handler|VSCodium)$"; tag = "+projects"; }
        { match.class = "^(VSCode|code-url-handler)$"; tag = "+projects"; }

        { match.class = "^([Dd]iscord|[Ww]ebCord|[Vv]esktop)$"; tag = "+im"; }
        { match.class = "^([Ff]erdium)$"; tag = "+im"; }
        { match.class = "^([Ww]hatsapp-for-linux)$"; tag = "+im"; }
        { match.class = "^(org.telegram.desktop|io.github.tdesktop_x64.TDesktop)$"; tag = "+im"; }
        { match.class = "^(teams-for-linux)$"; tag = "+im"; }

        { match.class = "^(gnome-disks|wihotspot(-gui)?)$"; tag = "+settings"; }
        { match.class = "^([Rr]ofi)$"; tag = "+settings"; }
        { match.class = "^(file-roller|org.gnome.FileRoller)$"; tag = "+settings"; }
        { match.class = "^(nm-applet|nm-connection-editor|blueman-manager)$"; tag = "+settings"; }
        { match.class = settingsClasses; tag = "+settings"; }
        { match.class = "^(nwg-look|qt5ct|qt6ct|[Yy]ad)$"; tag = "+settings"; }
        { match.class = "^(xdg-desktop-portal-gtk)$"; tag = "+settings"; }

        { match.title = "^(Picture-in-Picture)$"; move = pct "0.72" "0.07"; }

        # Zentrieren
        { match.class = "^([Ff]erdium)$"; center = true; }
        { match.class = settingsClasses; center = true; }
        { match = { class = "^([Tt]hunar)$"; title = "negative:(.*[Tt]hunar.*)"; }; center = true; }
        { match.title = "^(Authentication Required)$"; center = true; }

        # Floating
        { match.tag = "settings"; float = true; }
        { match.class = "^([Ff]erdium)$"; float = true; }
        { match.title = "^(Picture-in-Picture)$"; float = true; }
        { match.class = "^(mpv|com.github.rafostar.Clapper)$"; float = true; }
        { match.title = "^(Authentication Required)$"; float = true; }
        { match = { class = "^(codium|codium-url-handler|VSCodium)$"; title = "negative:(.*codium.*|.*VSCodium.*)"; }; float = true; }
        { match = { class = "^(com.heroicgameslauncher.hgl)$"; title = "negative:(Heroic Games Launcher)"; }; float = true; }
        { match = { class = "^([Ss]team)$"; title = "negative:^([Ss]team)$"; }; float = true; }
        { match = { class = "^([Tt]hunar)$"; title = "negative:(.*[Tt]hunar.*)"; }; float = true; }

        { match.title = "^(Add Folder to Workspace)$"; float = true; }
        { match.title = "^(Open Files)$"; float = true; }
        { match.title = "(wants to save)"; float = true; }

        # Größen
        { match.title = "^(Open Files)$"; size = pct "0.7" "0.6"; }
        { match.title = "^(Add Folder to Workspace)$"; size = pct "0.7" "0.6"; }
        { match.tag = "settings"; size = pct "0.7" "0.7"; }
        { match.class = "^([Ff]erdium)$"; size = pct "0.6" "0.7"; }

        # Opacity (aktiv / inaktiv)
        { match.tag = "browser"; opacity = "1.0 1.0"; }
        { match.tag = "projects"; opacity = "0.9 0.8"; }
        { match.tag = "im"; opacity = "0.94 0.86"; }
        { match.tag = "file-manager"; opacity = "0.9 0.8"; }
        { match.tag = "terminal"; opacity = "0.8 0.7"; }
        { match.tag = "settings"; opacity = "0.8 0.7"; }
        { match.class = "^(gedit|org.gnome.TextEditor|mousepad)$"; opacity = "0.8 0.7"; }
        { match.class = "^(seahorse)$"; opacity = "0.9 0.8"; }
        { match.title = "^(Picture-in-Picture)$"; opacity = "0.95 0.75"; }

        { match.title = "^(Picture-in-Picture)$"; pin = true; }

        { match.tag = "games"; no_blur = true; }
        { match.tag = "games"; fullscreen = true; }
      ];
    };

    extraConfig = ''
      ---------------
      -- AUTOSTART --
      ---------------
      hl.on("hyprland.start", function()
        hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP")
        hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP")
        hl.exec_cmd("nm-applet --indicator")
        hl.exec_cmd("lxqt-policykit-agent")
        hl.exec_cmd("pypr")
        hl.exec_cmd("awww-daemon")
        hl.dispatch(hl.dsp.focus({ workspace = 1 }))
      end)

      -----------------
      -- KEYBINDINGS --
      -----------------
      local mod = "SUPER"
      local function bind(keys, dsp, opts)
        return hl.bind(mod .. " + " .. keys, dsp, opts)
      end
      local exec = hl.dsp.exec_cmd

      --TODO: mehr auf variablen umstellen
      bind("N", exec([[dunstify "$(wl-paste)"]]))
      bind("SHIFT + E", exec([[hyprshot -s --mode active --mode output -o /tmp -f question.png; claude -p --allowed-tools "Read" --system-prompt "Respond with the correct answer to the question in the screenshot. Do not provide detailed explanations, only tell me the correct answer if possible." "Read /tmp/question.png and answer the question in it" | wl-copy && notify-send -t 150 Done]]))
      bind("Return", exec("${terminal}"))
      bind("SPACE", exec("rofi-launcher"))
      bind("SHIFT + W", exec("web-search"))
      bind("ALT + W", exec("wallsetter"))
      bind("SHIFT + N", exec("swaync-client -rs"))
      bind("W", exec("${browser}"))
      -- bind("E", exec("emopicker9000"))
      bind("S", exec("screenshootin"))
      bind("D", exec("${discordClient}"))
      bind("C", exec("hyprpicker -a"))
      bind("T", exec("pypr toggle term"))
      bind("SHIFT + T", exec("pypr toggle thunar"))
      bind("M", exec("pavucontrol"))
      bind("Q", hl.dsp.window.close())
      bind("L", exec("qylock-lock"))
      bind("P", exec("pypr toggle volume"))
      bind("SHIFT + P", hl.dsp.window.pseudo())
      bind("SHIFT + I", hl.dsp.layout("togglesplit"))
      bind("F", hl.dsp.window.fullscreen())
      bind("SHIFT + F", hl.dsp.window.float())
      bind("SHIFT + C", hl.dsp.exit())

      -- Fenster bewegen / Fokus wechseln (Pfeiltasten + vim-Keys)
      local dirs = {
        { "left", "h", "left" },
        { "right", "l", "right" },
        { "up", "k", "up" },
        { "down", "j", "down" },
      }
      for _, d in ipairs(dirs) do
        local arrow, vim, dir = d[1], d[2], d[3]
        bind("SHIFT + " .. arrow, hl.dsp.window.move({ direction = dir }))
        bind("SHIFT + " .. vim, hl.dsp.window.move({ direction = dir }))
        bind(arrow, hl.dsp.focus({ direction = dir }))
        bind(vim, hl.dsp.focus({ direction = dir }))
      end

      -- Workspaces 1-10 (0 = 10)
      for i = 1, 10 do
        local key = tostring(i % 10)
        bind(key, hl.dsp.focus({ workspace = i }))
        bind("SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
      end
      bind("ssharp", hl.dsp.focus({ workspace = 11 }))
      bind("SHIFT + ssharp", hl.dsp.window.move({ workspace = 11 }))
      bind("SHIFT + SPACE", hl.dsp.window.move({ workspace = "special" }))
      -- bind("SPACE", hl.dsp.workspace.toggle_special("special"))

      bind("CONTROL + right", hl.dsp.focus({ workspace = "e+1" }))
      bind("CONTROL + left", hl.dsp.focus({ workspace = "e-1" }))
      bind("mouse_down", hl.dsp.focus({ workspace = "e+1" }))
      bind("mouse_up", hl.dsp.focus({ workspace = "e-1" }))

      hl.bind("ALT + Tab", function()
        hl.dispatch(hl.dsp.window.cycle_next())
        hl.dispatch(hl.dsp.window.bring_to_top())
      end)

      -- Media-/Helligkeitstasten
      hl.bind("XF86AudioRaiseVolume", exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"))
      hl.bind("XF86AudioLowerVolume", exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"))
      hl.bind("XF86AudioMute", exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
      hl.bind("XF86AudioPlay", exec("playerctl play-pause"))
      hl.bind("XF86AudioPause", exec("playerctl play-pause"))
      hl.bind("XF86AudioNext", exec("playerctl next"))
      hl.bind("XF86AudioPrev", exec("playerctl previous"))
      hl.bind("XF86MonBrightnessDown", exec("brightnessctl set 5%-"))
      hl.bind("XF86MonBrightnessUp", exec("brightnessctl set +5%"))

      -- Maus: Fenster ziehen / skalieren
      bind("mouse:272", hl.dsp.window.drag(), { mouse = true })
      bind("mouse:273", hl.dsp.window.resize(), { mouse = true })
    '' + extraMonitorSettings;
  };

  # Wallpaper setzen – beim Login und bei jedem Rebuild (siehe setWallpaperScript).
  systemd.user.services.set-wallpaper = {
    Unit = {
      Description = "Wallpaper via awww setzen";
      After = [ "hyprland-session.target" ];
      PartOf = [ "hyprland-session.target" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${setWallpaperScript}";
    };
    Install.WantedBy = [ "hyprland-session.target" ];
  };
}
