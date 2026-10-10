{ config, palette, ... }:

let
  # Role registry, so a distro-provided terminal is what the click handlers open.
  terminal = config.green.apps.terminal.command;
in
{
  programs.waybar = {
    enable = true;

    # Bound to the Hyprland session rather than the default 
    # graphical-session.target so a Plasma login on the same machine does not get a bar too.
    systemd = {
      enable = true;
      targets = [ "hyprland-session.target" ];
    };

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 26;
        margin-top = 2;
        margin-left = 7;
        margin-right = 7;
        spacing = 4;

        modules-left = [
          "hyprland/workspaces"
        ];
        modules-center = [ "clock" ];
        modules-right = [
          "tray"
          "idle_inhibitor"
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
          format = "{:%b %d %H:%M}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt>{calendar}</tt>";
          format-alt = "{:%H:%M}";
        };

        "idle_inhibitor" = {
          format = "{icon}";
          format-icons = {
            activated = "󰅶";
            deactivated = "󰾪";
          };
          tooltip-format-activated = "Idle lock screen and screensaver are off. Click to allow them";
          tooltip-format-deactivated = "Idle lock screen and screensaver are on. Click to prevent them";
          start-activated = false;
        };

        "cpu" = {
          format = "<span size='160%' rise='-2pt'>󰍛</span> {usage}%";
          on-click = "${terminal} --title=float -e btop";
        };

        "memory" = {
          format = "<span size='160%' rise='-2pt'></span> {used}GB";
          on-click = "${terminal} --title=float -e btop";
        };

        "bluetooth" = {
          format = "󰂯";
          format-on = "󰂯";
          format-connected = "󰂱";
          format-off = "󰂲";
          format-disabled = "󰂲";
          tooltip-format = "{status}";
          tooltip-format-connected = "{device_alias}";
          on-click = "${terminal} --title=float -e bluetui";
        };

        "pulseaudio" = {
          format = "{volume}% <span size='160%' rise='-2pt'>{icon}</span>";
          format-bluetooth = "{volume}% <span size='160%' rise='-2pt'>{icon}</span><span size='115%'></span>";
          format-muted = "󰝟";
          format-icons = {
            headphone = "";
            default = [
              ""
              ""
            ];
          };
          on-click = "${terminal} --title=float -e wiremix";
        };

        "network" = {
          format-wifi = "󰖩";
          format-ethernet = "󰀂";
          format-linked = "󰖩";
          format-disconnected = "󰖪";
          tooltip-format = "{essid} ({signalStrength}%)";
          on-click = "${terminal} --title=float -e gazelle";
        };

        "battery" = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{capacity}% <span size='160%' rise='-2pt'>{icon}</span>";
          format-charging = "{capacity}% <span size='125%' rise='-1pt'></span>";
          format-plugged = "{capacity}% <span size='125%' rise='-1pt'></span>";
          on-click = "${terminal} --title=float -e btop";
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
          font-size: 10.56px;
          font-weight: bold;
      }

      window#waybar {
          background-color: transparent;
          color: #${palette.text};
      }

      /* Island panels behind each module group. The last value is the
         transparency knob: 0.0 is invisible, 1.0 is fully opaque. GTK's CSS
         parser rejects the #rrggbbaa form, so alpha() does the mixing. */
      .modules-left,
      .modules-center,
      .modules-right {
          background-color: alpha(#${palette.base}, 0.0);
          border-radius: 7.92px;
          padding: 0 2px;
      }

      #workspaces button {
          /* GTK gives buttons a default min-height (~24px) that outvotes the
             bar's `height` setting, so waybar silently grows the bar to fit. */
          min-height: 0;
          padding: 0 3px;
          margin: 1.76px;
          color: #${palette.overlay0};
          background: transparent;
          border-radius: 6.16px;
      }

      #workspaces button.active {
          color: #ffffff;
          background-color: alpha(#${palette.mauve}, 0.2);
      }

      #clock,
      #battery,
      #cpu,
      #memory,
      #disk,
      #temperature,
      #backlight,
      #pulseaudio,
      #wireplumber,
      #mode,
      #scratchpad,
      #mpd {
          padding: 0 10px;
          background-color: alpha(#${palette.mauve}, 0.2);
          border-radius: 6.16px;
          margin: 1.76px;
          color: #ffffff;
      }

      /* Icon-only pills (no text like the others carry) get extra horizontal
         padding so their pill width doesn't look cramped next to its siblings. */
      #bluetooth,
      #network,
      #idle_inhibitor {
          padding: 0 14px;
          background-color: alpha(#${palette.mauve}, 0.2);
          border-radius: 6.16px;
          margin: 1.76px;
          color: #ffffff;
          font-size: 17px;
      }

      /* Muted audio drops the volume text and shows only an icon, so it
         takes the icon-only pill sizing above. */
      #pulseaudio.muted {
          padding: 0 14px;
          font-size: 17px;
      }

      /* The bluetooth glyph is tall and narrow, so at the shared size it
         towers over the other icons. */
      #bluetooth {
          font-size: 11px;
      }

      /* The connected glyph adds dots on both sides, so the font squeezes it
         into the same cell width and it needs a bigger size to keep up. */
      #bluetooth.connected {
          font-size: 17px;
      }

      /* Same for the slash on the off glyph. */
      #bluetooth.off,
      #bluetooth.disabled {
          font-size: 14px;
      }

      /* Highlighted while idle lock/screensaver is being held off, so it's
         obvious the machine won't lock on its own. */
      #idle_inhibitor.activated {
          background-color: #${palette.red};
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
          font-size: 11.44px;
      }
    '';
  };
}
