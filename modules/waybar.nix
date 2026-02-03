{ config, pkgs, ... }:

{
  programs.waybar = {
    enable = true;
    
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 36;
        margin-top = 6;
        margin-left = 10;
        margin-right = 10;
        spacing = 4;
        
        modules-left = [ "hyprland/workspaces" "hyprland/window" ];
        modules-center = [ "clock" ];
        modules-right = [ "pulseaudio" "network" "battery" "tray" ];

        "hyprland/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
          format = "{icon}";
          format-icons = {
             "1" = "1";
             "2" = "2";
             "3" = "3";
             "4" = "4";
             "5" = "5";
             "6" = "6";
             "7" = "7";
             "8" = "8";
             "9" = "9";
             "10" = "10";
          };
        };
        
        "hyprland/window" = {
            max-length = 40;
        };

        "clock" = {
          format = "{:%H:%M}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt>{calendar}</tt>";
          format-alt = "{:%Y-%m-%d}";
        };

        "pulseaudio" = {
          format = "{volume}% {icon}";
          format-bluetooth = "{volume}% {icon}";
          format-muted = "";
          format-icons = {
            headphone = "";
            default = ["" ""];
          };
          on-click = "pavucontrol";
        };

        "network" = {
            format-wifi = "";
            format-ethernet = "󰀂";
            format-linked = "";
            format-disconnected = "⚠";
            tooltip-format = "{essid} ({signalStrength}%)";
        };

        "battery" = {
            states = {
                warning = 30;
                critical = 15;
            };
            format = "{capacity}% {icon}";
            format-charging = "{capacity}% ";
            format-plugged = "{capacity}% ";
            format-icons = ["" "" "" "" ""];
        };
      };
    };

    style = ''
        * {
            font-family: "JetBrainsMono Nerd Font";
            font-size: 13px;
            font-weight: bold;
        }

        window#waybar {
            background-color: rgba(26, 27, 38, 0.85);
            color: #c0caf5;
            border-radius: 10px;
        }

        #workspaces button {
            padding: 0 5px;
            color: #c0caf5;
            background: transparent;
        }

        #workspaces button.active {
            color: #7aa2f7;
            border-bottom: 2px solid #7aa2f7;
        }

        #clock,
        #battery,
        #cpu,
        #memory,
        #disk,
        #temperature,
        #backlight,
        #network,
        #pulseaudio,
        #wireplumber,
        #tray,
        #mode,
        #idle_inhibitor,
        #scratchpad,
        #mpd {
            padding: 0 10px;
            background-color: rgba(65, 72, 104, 0.4);
            border-radius: 6px;
            margin: 4px 2px;
            color: #c0caf5;
        }

        #clock {
            background-color: transparent;
            font-size: 15px;
        }

        #battery {
            color: #9ece6a;
        }

        #pulseaudio {
            color: #bb9af7;
        }
        
        #network {
            color: #7dcfff;
        }
    '';
  };
}
