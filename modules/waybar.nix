{ ... }:

{
  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        margin-top = 6;
        margin-left = 10;
        margin-right = 10;
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
          on-click = "ghostty -e btop";
        };

        "memory" = {
          format = "Mem: {used}GB";
          on-click = "ghostty -e btop";
        };

        "bluetooth" = {
          format = " {status}";
          on-click = "ghostty -e bluetui";
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
          on-click = "ghostty -e wiremix";
        };

        "network" = {
          format-wifi = "";
          format-ethernet = "󰀂";
          format-linked = "";
          format-disconnected = "⚠";
          tooltip-format = "{essid} ({signalStrength}%)";
          on-click = "ghostty -e gazelle";
        };

        "battery" = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{capacity}% {icon}";
          format-charging = "{capacity}% ";
          format-plugged = "{capacity}% ";
          on-click = "ghostty -e btop";
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
          background-color: rgba(65, 72, 104, 0.4);
          border-radius: 6px;
          margin: 4px 2px;
          color: #c0caf5;
      }

      #clock {
          background-color: transparent;
          font-size: 15px;
      }
    '';
  };
}
