{ ... }:

{
  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 22;
        margin-top = 7;
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
          format = "{:%H:%M %m-%d}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt>{calendar}</tt>";
          format-alt = "{:%H:%M}";
        };

        "cpu" = {
          format = "󰻠 {usage}%";
          on-click = "ghostty --title=float -e btop";
        };

        "memory" = {
          format = "󰍛 {used}GB";
          on-click = "ghostty --title=float -e btop";
        };

        "bluetooth" = {
          format = "󰂯";
          format-on = "󰂯";
          format-connected = "󰂱";
          format-off = "󰂲";
          format-disabled = "󰂲";
          tooltip-format = "{status}";
          tooltip-format-connected = "{device_alias}";
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
          format-wifi = "󰖩";
          format-ethernet = "󰀂";
          format-linked = "󰖩";
          format-disconnected = "󰖪";
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
          /* The "Mono" variant scales every icon to a single cell and centres
             it in that cell; the plain variant leaves wide icons overhanging
             to the right, which knocks glyph-only modules off centre. */
          font-family: "JetBrainsMono Nerd Font Mono";
          font-size: 12px;
          font-weight: bold;
      }

      window#waybar {
          background-color: transparent;
          color: #cdd6f4;
      }

      /* Island panels behind each module group. The last value is the
         transparency knob: 0.0 is invisible, 1.0 is fully opaque. */
      .modules-left,
      .modules-center,
      .modules-right {
          background-color: rgba(30, 30, 46, 0.0);
          border-radius: 9px;
          padding: 0 4px;
      }

      #workspaces button {
          padding: 0 6px;
          margin: 2px;
          color: #cdd6f4;
          background: transparent;
          border-radius: 7px;
      }

      #workspaces button.active {
          color: #313244;
          background-color: rgb(203, 166, 247);
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
      #mode,
      #idle_inhibitor,
      #scratchpad,
      #mpd {
          padding: 0 8px;
          background-color: rgb(203, 166, 247);
          border-radius: 7px;
          margin: 2px;
          color: #313244;
      }

      /* The tray box is excluded from the pill rule above: with no status
         icons running it would render as a stray coloured nub. */
      #tray {
          background-color: transparent;
          padding: 0;
          margin: 0;
      }

      /* The clock keeps the shared pill fill and text colour; it only
         opts out of the common font size. */
      #clock {
          font-size: 13px;
      }
    '';
  };
}
