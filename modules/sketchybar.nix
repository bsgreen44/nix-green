{ pkgs, lib, ... }:

# SketchyBar status bar — the macOS analogue of modules/waybar.nix. Self-contained
# like waybar.nix: installs the binary, writes the config + plugin scripts, and runs
# it as a keep-alive launchd agent. Catppuccin Mocha applied by hand with the same
# hex as waybar (bg #1e1e2e, fg #cdd6f4, accent #cba6f7); SketchyBar uses 0xAARRGGBB.
#
# Widgets mirror waybar's (modules/waybar.nix): AeroSpace workspaces, clock, cpu,
# memory, volume, wifi, battery. Refresh intervals are kept in seconds (volume is
# event-driven) to stay light — see the MacBook Air resource note in the plan.
#
# darwin-only; guarded so it's inert if ever imported on Linux (like modules/raycast.nix).
lib.mkIf pkgs.stdenv.isDarwin {
  home.packages = [ pkgs.sketchybar ];

  # Keep-alive agent so the bar runs at login and restarts if it dies. It reads
  # ~/.config/sketchybar/sketchybarrc (written below). PATH covers sketchybar plus
  # the system tools the plugins call (pmset, top, networksetup, osascript, ...).
  launchd.agents.sketchybar = {
    enable = true;
    config = {
      ProgramArguments = [ "${pkgs.sketchybar}/bin/sketchybar" ];
      KeepAlive = true;
      RunAtLoad = true;
      EnvironmentVariables.PATH = "${pkgs.sketchybar}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
    };
  };

  xdg.configFile = {
    "sketchybar/sketchybarrc" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash

        PLUGIN_DIR="$CONFIG_DIR/plugins"

        # Catppuccin Mocha (0xAARRGGBB)
        BAR_BG=0xee1e1e2e
        ITEM_BG=0x9931323b
        FG=0xffcdd6f4

        sketchybar --bar height=32 \
                         position=top \
                         padding_left=8 \
                         padding_right=8 \
                         color=$BAR_BG \
                         corner_radius=12 \
                         margin=6 \
                         y_offset=4

        sketchybar --default updates=when_shown \
                             icon.font="JetBrainsMono Nerd Font:Bold:14.0" \
                             label.font="JetBrainsMono Nerd Font:Bold:13.0" \
                             icon.color=$FG \
                             label.color=$FG \
                             background.color=$ITEM_BG \
                             background.corner_radius=8 \
                             background.height=24 \
                             label.padding_left=6 \
                             label.padding_right=6 \
                             padding_left=3 \
                             padding_right=3

        # Workspaces (AeroSpace) — highlighted via the trigger fired by
        # exec-on-workspace-change in modules/aerospace.nix.
        sketchybar --add event aerospace_workspace_change

        for sid in 1 2 3 4 5 6 7 8 9; do
          sketchybar --add item space.$sid left \
                     --subscribe space.$sid aerospace_workspace_change \
                     --set space.$sid \
                           background.drawing=off \
                           icon.drawing=off \
                           label="$sid" \
                           script="$PLUGIN_DIR/aerospace.sh $sid"
        done

        # Clock (center)
        sketchybar --add item clock center \
                   --set clock update_freq=10 background.drawing=off icon.drawing=off \
                         script="$PLUGIN_DIR/clock.sh"

        # Right side (added right-to-left; mirrors waybar's modules-right)
        sketchybar --add item battery right \
                   --set battery update_freq=120 script="$PLUGIN_DIR/battery.sh" \
                   --subscribe battery power_source_change system_woke

        sketchybar --add item wifi right \
                   --set wifi update_freq=30 script="$PLUGIN_DIR/wifi.sh"

        sketchybar --add item volume right \
                   --set volume script="$PLUGIN_DIR/volume.sh" \
                   --subscribe volume volume_change

        sketchybar --add item memory right \
                   --set memory update_freq=5 script="$PLUGIN_DIR/memory.sh"

        sketchybar --add item cpu right \
                   --set cpu update_freq=10 script="$PLUGIN_DIR/cpu.sh"

        sketchybar --update

        # Initialise the workspace highlight (AeroSpace starts on workspace 1).
        sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE=1
      '';
    };

    "sketchybar/plugins/aerospace.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
          sketchybar --set "$NAME" background.drawing=on background.color=0xffcba6f7 label.color=0xff1e1e2e
        else
          sketchybar --set "$NAME" background.drawing=off label.color=0xffcdd6f4
        fi
      '';
    };

    "sketchybar/plugins/clock.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        sketchybar --set "$NAME" label="$(date '+%H:%M %m-%d')"
      '';
    };

    "sketchybar/plugins/cpu.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        cpu=$(top -l 1 | awk '/CPU usage/ {gsub("%","",$7); printf "%.0f", 100-$7}')
        sketchybar --set "$NAME" label="CPU: $cpu%"
      '';
    };

    "sketchybar/plugins/memory.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        free=$(memory_pressure | awk '/free percentage/ {gsub("%","",$5); print $5}')
        used=$((100 - free))
        sketchybar --set "$NAME" label="Mem: $used%"
      '';
    };

    "sketchybar/plugins/volume.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        if [ "$SENDER" = "volume_change" ]; then
          vol="$INFO"
        else
          vol=$(osascript -e "output volume of (get volume settings)")
        fi
        sketchybar --set "$NAME" label="Vol: $vol%"
      '';
    };

    "sketchybar/plugins/wifi.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        ssid=$(networksetup -getairportnetwork en0 | sed 's/^Current Wi-Fi Network: //')
        case "$ssid" in
          *"not associated"*|"") sketchybar --set "$NAME" label="Wi-Fi: off" ;;
          *) sketchybar --set "$NAME" label="$ssid" ;;
        esac
      '';
    };

    "sketchybar/plugins/battery.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        pct=$(pmset -g batt | grep -Eo "[0-9]+%" | head -1 | tr -d '%')
        if pmset -g batt | grep -q "AC Power"; then
          sketchybar --set "$NAME" label="Bat: $pct% (chg)"
        else
          sketchybar --set "$NAME" label="Bat: $pct%"
        fi
      '';
    };
  };
}
