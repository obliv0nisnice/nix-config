{
  pkgs,
  lib,
  host,
  config,
  osConfig,
  vars,
  ...
}: let
  betterTransition = "all 0.3s cubic-bezier(.55,-0.68,.48,1.682)";
  inherit (vars) clock24h;

  # GPU-Anzeige nur auf dem PC (Host "nvidia"). nvidia-smi kommt direkt aus dem
  # installierten Treiberpaket, damit das Skript nicht vom PATH des
  # Waybar-Services abhängt.
  showGpu = host == "nvidia";
  gpuinfo = pkgs.writeShellApplication {
    name = "gpuinfo";
    runtimeInputs = [ pkgs.jq osConfig.hardware.nvidia.package.bin ];
    text = builtins.readFile ./scripts/gpuinfo.sh;
  };

  # VPN-Status auf allen Hosts – damit man immer sieht, falls eins aktiv ist.
  vpninfo = pkgs.writeShellApplication {
    name = "vpninfo";
    runtimeInputs = with pkgs; [ iproute2 jq networkmanager coreutils gnugrep ];
    text = builtins.readFile ./scripts/vpninfo.sh;
  };
in
  with lib; {
    # Configure & Theme Waybar
    programs.waybar = {
      enable = true;
      package = pkgs.waybar;
      systemd = {
        enable = true;
        targets = [ "hyprland-session.target" ];
      };
      settings = [
        ({
          layer = "top";
          position = "top";
          modules-center = ["hyprland/workspaces"];
          modules-left = [
            "custom/startmenu"
            "hyprland/window"
            "pulseaudio"
            "custom/cpu"
          ] ++ optional showGpu "custom/gpu" ++ [
            "memory"
            "idle_inhibitor"
          ] ++ optional (host == "macbook") "custom/kbd_backlight";
          modules-right = [
            "custom/hyprbindings"
            "custom/nvimbindings"
            "custom/notification"
            "custom/exit"
            "custom/vpn"
            "battery"
            "power-profiles-daemon"
            "tray"
            "clock"
          ];

          "hyprland/workspaces" = {
            format = "{name}";
            format-icons = {
              default = " ";
              active = " ";
              urgent = " ";
            };
            ignore-workspaces = [ "^11$" ];
            on-scroll-up = "hyprctl dispatch 'hl.dsp.focus({ workspace = \"e+1\" })'";
            on-scroll-down = "hyprctl dispatch 'hl.dsp.focus({ workspace = \"e-1\" })'";
          };
          "clock" = {
            format =
              if clock24h == true
              then '' {:L%H:%M}''
              else '' {:L%I:%M %p}'';
            tooltip = true;
            tooltip-format = "<big>{:%A, %d.%B %Y }</big>\n<tt><small>{calendar}</small></tt>";
          };
          "hyprland/window" = {
            max-length = 22;
            separate-outputs = false;
            rewrite = {
              "" = " 🙈 No Windows? ";
            };
          };
          "memory" = {
            interval = 10;
            format = " {}%";
            tooltip = true;
          };
          "cpu" = {
            interval = 10;
            format = " {usage:2}%";
            tooltip = true;
          };
          "custom/cpu" = {
            interval = 10;
            format = "{}";
            exec = ./scripts/cpuinfo.sh;
            return-type = "json";
            tooltip = true;
          };
        } // optionalAttrs showGpu {
          "custom/gpu" = {
            interval = 10;
            format = "{}";
            exec = "${gpuinfo}/bin/gpuinfo";
            return-type = "json";
            tooltip = true;
          };
        } // {
          "custom/vpn" = {
            interval = 5;
            format = "{}";
            exec = "${vpninfo}/bin/vpninfo";
            return-type = "json";
            tooltip = true;
          };

          "disk" = {
            format = " {free}";
            tooltip = true;
          };
          "network" = {
            format-icons = [
              "󰤯"
              "󰤟"
              "󰤢"
              "󰤥"
              "󰤨"
            ];
            format-ethernet = " {bandwidthDownOctets}";
            format-wifi = "{icon} {signalStrength}%";
            format-disconnected = "󰤮";
            tooltip = false;
          };
          "tray" = {
            spacing = 12;
          };
          "pulseaudio" = {
            format = "{icon} {volume}% {format_source}";
            format-bluetooth = "{volume}% {icon} {format_source}";
            format-bluetooth-muted = " {icon} {format_source}";
            format-muted = " {format_source}";
            format-source = " {volume}%";
            format-source-muted = "";
            format-icons = {
              headphone = "";
              hands-free = "";
              headset = "";
              phone = "";
              portable = "";
              car = "";
              default = [
                ""
                ""
                ""
              ];
            };
            on-click = "sleep 0.1 && pavucontrol";
          };
          "custom/exit" = {
            tooltip = false;
            format = "";
            on-click = "sleep 0.1 && wlogout";
          };
          "custom/startmenu" = {
            tooltip = false;
            format = "";
            # exec = "rofi -show drun";
            on-click = "sleep 0.1 && rofi-launcher";
          };
          "custom/hyprbindings" = {
            tooltip = false;
            format = "󱕴";
            on-click = "sleep 0.1 && list-keybinds";
          };
          "custom/nvimbindings" = {
            tooltip = false;
            format = "";
            on-click = "sleep 0.1 && nvim-cheatsheet";
          };
          "idle_inhibitor" = {
            format = "{icon}";
            format-icons = {
              activated = "";
              deactivated = "";
            };
            tooltip = "true";
          };
          "custom/kbd_backlight" = {
            format = "{}";
            return-type = "json";
            exec = "kbd-backlight";
            interval = 5;
            on-click = "kbd-backlight toggle";
            on-scroll-up = "kbd-backlight up";
            on-scroll-down = "kbd-backlight down";
            tooltip = true;
          };
          "custom/notification" = {
            tooltip = false;
            format = "{icon} {text}";
            format-icons = {
              notification = "<span foreground='red'><sup></sup></span>";
              none = "";
              dnd-notification = "<span foreground='red'><sup></sup></span>";
              dnd-none = "";
              inhibited-notification = "<span foreground='red'><sup></sup></span>";
              inhibited-none = "";
              dnd-inhibited-notification = "<span foreground='red'><sup></sup></span>";
              dnd-inhibited-none = "";
            };
            return-type = "json";
            exec-if = "which swaync-client";
            exec = "swaync-client -swb";
            on-click = "sleep 0.1 && task-waybar";
            escape = true;
          };
          "battery" = {
            states = {
              warning = 30;
              critical = 15;
            };
            format = "{icon} {capacity}%";
            format-charging = "󰂄 {capacity}%";
            format-plugged = "󱘖 {capacity}%";
            format-icons = [
              "󰁺"
              "󰁻"
              "󰁼"
              "󰁽"
              "󰁾"
              "󰁿"
              "󰂀"
              "󰂁"
              "󰂂"
              "󰁹"
            ];
            on-click = "";
            tooltip = false;
          };
          "power-profiles-daemon" = {
            format = "{icon}";
            tooltip = true;
            tooltip-format = "{profile}";
            format-icons = {
              default = "󰗑";
              performance = "󰓅";
              balanced = "󰾅";
              power-saver = "󰾆";
              };
            };
        })
      ];
      style = concatStrings [
        ''
          * {
            font-family: JetBrainsMono Nerd Font Mono;
            font-size: 16px;
            border-radius: 0px;
            border: none;
            min-height: 0px;
          }
          window#waybar {
            background: rgba(0,0,0,0);
          }
          #workspaces {
            color: #${config.lib.stylix.colors.base00};
            background: #${config.lib.stylix.colors.base01};
            margin: 4px 4px;
            padding: 5px 5px;
            border-radius: 16px;
          }
          #workspaces button {
            font-weight: bold;
            padding: 0px 5px;
            margin: 0px 3px;
            border-radius: 16px;
            color: #${config.lib.stylix.colors.base00};
            background: linear-gradient(45deg, #${config.lib.stylix.colors.base08}, #${config.lib.stylix.colors.base0D});
            opacity: 0.5;
            transition: ${betterTransition};
          }
          #workspaces button.active {
            font-weight: bold;
            padding: 0px 5px;
            margin: 0px 3px;
            border-radius: 16px;
            color: #${config.lib.stylix.colors.base00};
            background: linear-gradient(45deg, #${config.lib.stylix.colors.base08}, #${config.lib.stylix.colors.base0D});
            transition: ${betterTransition};
            opacity: 1.0;
            min-width: 40px;
          }
          #workspaces button:hover {
            font-weight: bold;
            border-radius: 16px;
            color: #${config.lib.stylix.colors.base00};
            background: linear-gradient(45deg, #${config.lib.stylix.colors.base08}, #${config.lib.stylix.colors.base0D});
            opacity: 0.8;
            transition: ${betterTransition};
          }
          tooltip {
            background: #${config.lib.stylix.colors.base00};
            border: 1px solid #${config.lib.stylix.colors.base08};
            border-radius: 12px;
          }
          tooltip label {
            color: #${config.lib.stylix.colors.base08};
          }
          #window, #pulseaudio, #memory, #idle_inhibitor, #custom-kbd_backlight {
            font-weight: bold;
            margin: 4px 0px;
            margin-left: 7px;
            padding: 0px 18px;
            background: #${config.lib.stylix.colors.base04};
            color: #${config.lib.stylix.colors.base00};
            border-radius: 24px 10px 24px 10px;
          }
          #custom-kbd_backlight.off {
            opacity: 0.5;
          }
          #custom-cpu, #custom-gpu {
            font-weight: bold;
            margin: 4px 0px;
            margin-left: 7px;
            padding: 0px 18px;
            background: #${config.lib.stylix.colors.base04};
            color: #${config.lib.stylix.colors.base00};
            border-radius: 24px 10px 24px 10px;
            border: 2px solid #${config.lib.stylix.colors.base0D};
          }
          #custom-gpu.medium {
            border-color: #${config.lib.stylix.colors.base0A};
          }
          #custom-gpu.high, #custom-gpu.error {
            border-color: #${config.lib.stylix.colors.base08};
          }
          #custom-startmenu {
            color: #${config.lib.stylix.colors.base0B};
            background: #${config.lib.stylix.colors.base02};
            font-size: 28px;
            margin: 0px;
            padding: 0px 30px 0px 15px;
            border-radius: 0px 0px 40px 0px;
          }
          #custom-hyprbindings, #custom-nvimbindings, #network, #battery, #power-profiles-daemon,
          #custom-notification, #tray, #custom-exit, #custom-vpn {
            font-weight: bold;
            background: #${config.lib.stylix.colors.base0F};
            color: #${config.lib.stylix.colors.base00};
            margin: 4px 0px;
            margin-right: 7px;
            border-radius: 10px 24px 10px 24px;
            padding: 0px 18px;
          }
          #custom-vpn.active {
            color: #${config.lib.stylix.colors.base0B};
            background: #${config.lib.stylix.colors.base01};
          }
          #custom-vpn.inactive {
            opacity: 0.45;
          }
          #clock {
            font-weight: bold;
            color: #0D0E15;
            background: linear-gradient(90deg, #${config.lib.stylix.colors.base0E}, #${config.lib.stylix.colors.base0C});
            margin: 0px;
            padding: 0px 15px 0px 30px;
            border-radius: 0px 0px 0px 40px;
          }
        ''
      ];
    };
  }
