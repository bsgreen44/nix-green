{ config, pkgs, lib, palette, ... }:

# SketchyBar status bar - the macOS analogue of modules/waybar.nix. Self-contained
# like waybar.nix: installs the binary, writes the config + plugin scripts, and runs
# it as a keep-alive launchd agent. Catppuccin Mocha comes from modules/palette.nix,
# the same source waybar.nix uses; SketchyBar wants 0xAARRGGBB, so only the RGB half
# interpolates and the leading alpha byte stays literal.
#
# Styled like waybar: a fully transparent bar with mauve icon/text pills and a
# Nerd Font glyph per widget (glyphs are copied from waybar.nix). Widgets: AeroSpace
# workspaces 1-10 (left), then idle inhibitor (caffeinate), cpu, memory, volume,
# bluetooth, network, battery, clock (right; the notch hides the center). The tray
# is omitted - macOS menu bar extras have no SketchyBar equivalent. Refresh
# intervals are kept in seconds (volume is event-driven) to stay light.
#
# darwin-only; guarded so it's inert if ever imported on Linux (like modules/raycast.nix).
lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
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

        # Catppuccin Mocha, from modules/palette.nix (0xAARRGGBB)
        PILL=0xff${palette.mauve}
        PILL_FG=0xff${palette.surface0}
        FG=0xff${palette.text}

        MONITOR="open -a 'Activity Monitor'"

        # Transparent bar; the pills carry the colour, like waybar's islands.
        sketchybar --bar height=20 \
                         position=top \
                         padding_left=2 \
                         padding_right=2 \
                         color=0x00000000 \
                         margin=7 \
                         y_offset=7

        # Every item is a mauve pill by default (waybar's shared pill rule).
        # The Mono Nerd Font variant keeps glyphs in a single centred cell.
        sketchybar --default updates=when_shown \
                             icon.font="JetBrainsMono Nerd Font Mono:Bold:13.0" \
                             label.font="JetBrainsMono Nerd Font Mono:Bold:11.0" \
                             icon.color=$PILL_FG \
                             label.color=$PILL_FG \
                             background.color=$PILL \
                             background.corner_radius=6 \
                             background.height=20 \
                             icon.padding_left=5 \
                             icon.padding_right=3 \
                             label.padding_left=0 \
                             label.padding_right=5 \
                             padding_left=2 \
                             padding_right=2

        # Workspaces (AeroSpace), like waybar's hyprland/workspaces: only workspaces
        # holding windows (plus the focused one) are shown, and the focused one is a
        # mauve pill. One hidden controller item redraws all ten on each event, fired
        # by exec-on-workspace-change / on-focus-changed in modules/aerospace.nix.
        sketchybar --add event aerospace_workspace_change

        for sid in 1 2 3 4 5 6 7 8 9 10; do
          sketchybar --add item space.$sid left \
                     --set space.$sid \
                           drawing=off \
                           background.drawing=off \
                           icon.drawing=off \
                           label="$sid" \
                           label.color=$FG \
                           label.padding_left=5 \
                           label.padding_right=5
        done

        # updates=on: the controller never draws, and when_shown would skip it.
        sketchybar --add item aerospace left \
                   --set aerospace drawing=off updates=on \
                         script="$PLUGIN_DIR/aerospace.sh" \
                   --subscribe aerospace aerospace_workspace_change front_app_switched system_woke

        # Right side (added right-to-left; mirrors waybar's modules-right). The
        # clock sits at the far right instead of waybar's center slot, because the
        # MacBook notch covers the middle of the bar.
        sketchybar --add item clock right \
                   --set clock update_freq=10 icon.drawing=off \
                         label.font="JetBrainsMono Nerd Font Mono:Bold:12.0" \
                         label.padding_left=5 \
                         script="$PLUGIN_DIR/clock.sh"

        sketchybar --add item battery right \
                   --set battery update_freq=120 icon.drawing=off \
                         label.padding_left=5 \
                         click_script="$MONITOR" \
                         script="$PLUGIN_DIR/battery.sh" \
                   --subscribe battery power_source_change system_woke

        # Icon-only pills get the wide padding, like waybar's icon-only CSS rule.
        sketchybar --add item network right \
                   --set network update_freq=30 label.drawing=off \
                         icon.padding_left=14 icon.padding_right=14 \
                         click_script="open 'x-apple.systempreferences:com.apple.wifi-settings-extension'" \
                         script="$PLUGIN_DIR/network.sh" \
                   --subscribe network wifi_change system_woke

        sketchybar --add item bluetooth right \
                   --set bluetooth update_freq=30 label.drawing=off \
                         icon.padding_left=14 icon.padding_right=14 \
                         click_script="open 'x-apple.systempreferences:com.apple.BluetoothSettings'" \
                         script="$PLUGIN_DIR/bluetooth.sh" \
                   --subscribe bluetooth system_woke

        sketchybar --add item volume right \
                   --set volume icon.drawing=off \
                         label.padding_left=5 \
                         click_script="open 'x-apple.systempreferences:com.apple.Sound-Settings.extension'" \
                         script="$PLUGIN_DIR/volume.sh" \
                   --subscribe volume volume_change

        sketchybar --add item memory right \
                   --set memory update_freq=5 \
                         click_script="$MONITOR" \
                         script="$PLUGIN_DIR/memory.sh"

        sketchybar --add item cpu right \
                   --set cpu update_freq=10 \
                         click_script="$MONITOR" \
                         script="$PLUGIN_DIR/cpu.sh"

        sketchybar --add item idle_inhibitor right \
                   --set idle_inhibitor update_freq=10 label.drawing=off \
                         icon.padding_left=14 icon.padding_right=14 \
                         click_script="$PLUGIN_DIR/idle_inhibitor.sh toggle" \
                         script="$PLUGIN_DIR/idle_inhibitor.sh"

        sketchybar --update

        # Draw the workspaces once at startup.
        sketchybar --trigger aerospace_workspace_change
      '';
    };

    "sketchybar/plugins/aerospace.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        aerospace=${config.programs.aerospace.package}/bin/aerospace

        # exec-on-workspace-change passes the focused workspace; other events don't.
        focused="''${FOCUSED_WORKSPACE:-$($aerospace list-workspaces --focused)}"
        used=" $($aerospace list-workspaces --monitor all --empty no | tr '\n' ' ') "

        args=()
        for sid in 1 2 3 4 5 6 7 8 9 10; do
          if [ "$sid" = "$focused" ]; then
            args+=(--set "space.$sid" drawing=on background.drawing=on label.color=0xff${palette.surface0})
          elif [[ "$used" == *" $sid "* ]]; then
            args+=(--set "space.$sid" drawing=on background.drawing=off label.color=0xff${palette.text})
          else
            args+=(--set "space.$sid" drawing=off)
          fi
        done
        sketchybar "''${args[@]}"
      '';
    };

    "sketchybar/plugins/clock.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        sketchybar --set "$NAME" label="$(date '+%m-%d %H:%M')"
      '';
    };

    # Mirrors waybar's idle_inhibitor: a click toggles a background caffeinate that
    # holds off display/idle sleep (and so the lock screen). It starts deactivated.
    "sketchybar/plugins/idle_inhibitor.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        NAME=idle_inhibitor
        pidfile="/tmp/sketchybar-caffeinate.$(id -u).pid"

        running() {
          [ -f "$pidfile" ] || return 1
          case "$(ps -p "$(cat "$pidfile")" -o comm= 2>/dev/null)" in
            *caffeinate) return 0 ;;
            *) return 1 ;;
          esac
        }

        if [ "$1" = "toggle" ]; then
          if running; then
            kill "$(cat "$pidfile")"
            rm -f "$pidfile"
          else
            nohup caffeinate -dimsu >/dev/null 2>&1 &
            echo $! >"$pidfile"
          fi
        fi

        if running; then
          sketchybar --set "$NAME" icon="󰅶" background.color=0xff${palette.red}
        else
          sketchybar --set "$NAME" icon="󰾪" background.color=0xff${palette.mauve}
        fi
      '';
    };

    "sketchybar/plugins/cpu.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        cpu=$(top -l 1 | awk '/CPU usage/ {gsub("%","",$7); printf "%.0f", 100-$7}')
        sketchybar --set "$NAME" icon="󰍛" label="$cpu%"
      '';
    };

    "sketchybar/plugins/memory.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Used = active + wired + compressor pages, in GiB (waybar's {used}GB).
        used=$(vm_stat | awk '
          /page size of/ {size=$8}
          /Pages active/ {a=$3}
          /Pages wired down/ {w=$4}
          /Pages occupied by compressor/ {c=$5}
          END {printf "%.1f", (a + w + c) * size / 1073741824}')
        sketchybar --set "$NAME" icon="" label="''${used}GB"
      '';
    };

    "sketchybar/plugins/volume.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Query both values every time: volume_change only carries the level.
        read -r vol muted < <(osascript -e 'set s to get volume settings' \
          -e '(output volume of s as text) & " " & (output muted of s as text)')

        case "$vol" in
          ""|*[!0-9]*) sketchybar --set "$NAME" label="--%" ; exit 0 ;;
        esac

        if [ "$muted" = "true" ]; then
          sketchybar --set "$NAME" label=""
        elif [ "$vol" -lt 50 ]; then
          sketchybar --set "$NAME" label="$vol% "
        else
          sketchybar --set "$NAME" label="$vol% "
        fi
      '';
    };

    "sketchybar/plugins/bluetooth.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        blueutil=${pkgs.blueutil}/bin/blueutil

        if [ "$($blueutil -p)" != "1" ]; then
          icon="󰂲"
        elif [ -n "$($blueutil --connected)" ]; then
          icon="󰂱"
        else
          icon="󰂯"
        fi
        sketchybar --set "$NAME" icon="$icon"
      '';
    };

    # Icon only: the SSID is not used because `networksetup -getairportnetwork`
    # is redacted on recent macOS. The default route's interface decides.
    "sketchybar/plugins/network.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        iface=$(route -n get default 2>/dev/null | awk '/interface:/ {print $2}')

        if [ -z "$iface" ]; then
          icon="󰖪"
        else
          port=$(networksetup -listallhardwareports | awk -v i="$iface" '
            /^Hardware Port:/ {sub(/^Hardware Port: /, ""); p=$0}
            /^Device:/ && $2 == i {print p; exit}')
          case "$port" in
            Wi-Fi) icon="󰖩" ;;
            *) icon="󰀂" ;;
          esac
        fi
        sketchybar --set "$NAME" icon="$icon"
      '';
    };

    "sketchybar/plugins/battery.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        batt=$(pmset -g batt)
        pct=$(echo "$batt" | grep -Eo "[0-9]+%" | head -1 | tr -d '%')

        # No battery (desktop Mac): hide the pill.
        if [ -z "$pct" ]; then
          sketchybar --set "$NAME" drawing=off
          exit 0
        fi

        # Five levels, like waybar's format-icons; charging and plugged share a glyph.
        icons=("" "" "" "" "")
        idx=$((pct * 5 / 100))
        [ "$idx" -gt 4 ] && idx=4

        if echo "$batt" | grep -q "AC Power"; then
          sketchybar --set "$NAME" drawing=on label="$pct% "
        else
          sketchybar --set "$NAME" drawing=on label="$pct% ''${icons[$idx]}"
        fi
      '';
    };
  };
}
