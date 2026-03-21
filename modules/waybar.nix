{ ... }:

{
  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        margin-top = 3;
        margin-left = 7;
        margin-right = 7;
        spacing = 4;

        modules-left = [
          "hyprland/workspaces"
        ];
        modules-center = [ "clock" ];
        modules-right = [
          "tray"
          "cpu"
          "memory"
          "pulseaudio"
          "bluetooth"
          "network"
          "battery"
        ];

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
          format-alt = "{:%H:%M %m-%d}";
        };

        "cpu" = {
          format = "CPU: {usage}%";
          on-click = "ghostty --title=float -e btop";
        };

        "memory" = {
          format = "Mem: {used}GB";
          on-click = "ghostty --title=float -e btop";
        };

        "bluetooth" = {
          format = " {status}";
          on-click = "ghostty --title=float -e bluetui";
        };

        "pulseaudio" = {
          format = "{volume}% {icon}";
          format-bluetooth = "{volume}% {icon}";
          format-muted = "";
          format-icons = {
            headphone = "";
            default = [
              ""
              ""
            ];
          };
          on-click = "ghostty --title=float -e wiremix";
        };

        "network" = {
          format-wifi = "";
          format-ethernet = "󰀂";
          format-linked = "";
          format-disconnected = "⚠";
          tooltip-format = "{essid} ({signalStrength}%)";
          on-click = "ghostty --title=float -e gazelle";
        };

        "battery" = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{capacity}% {icon}";
          format-charging = "{capacity}% ";
          format-plugged = "{capacity}% ";
          on-click = "ghostty --title=float -e btop";
          format-icons = [
            ""
            ""
            ""
            ""
            ""
          ];
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
          background-color: rgba(30, 30, 46, 0.90);
          color: #cdd6f4;
          border-radius: 12px;
      }

      #workspaces button {
          padding: 0 5px;
          color: #cdd6f4;
          background: transparent;
      }

      #workspaces button.active {
          color: #cba6f7;
          border-bottom: 2px solid #cba6f7;
      }

      #clock,
      #battery,
      #bluetooth,
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
          background-color: rgba(49, 50, 68, 0.60);
          border-radius: 8px;
          margin: 4px 2px;
          color: #cba6f7;
      }

      #clock {
          background-color: transparent;
          font-size: 15px;
      }
    '';
  };
}
