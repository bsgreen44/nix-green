{ pkgs, lib, ... }:

# SketchyBar - a small extension of the native macOS menu bar, not a status bar of
# its own. The menu bar already shows the clock, battery, volume, Wi-Fi and
# Bluetooth, so SketchyBar adds only what macOS lacks, styled like a native menu
# extra (no background, white SF Pro text) and placed against the notch: the
# active Desktop number left of it, and a screen-awake (caffeinate) toggle right
# of it. The system is forced to Dark mode (nix-darwin/configuration.nix), so the
# menu bar text is always white. SF Pro comes from the font-sf-pro cask there.
#
# darwin-only; guarded so it's inert if ever imported on Linux (like modules/raycast.nix).
lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  home.packages = [ pkgs.sketchybar ];

  # Keep-alive agent so the bar runs at login and restarts if it dies. It reads
  # ~/.config/sketchybar/sketchybarrc (written below). PATH covers sketchybar plus
  # the system tools the plugins call (caffeinate, ps, ...).
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

        # Transparent and as tall as the native menu bar on the notched built-in
        # display. notch_width is the gap the q/e positions leave for the notch.
        # With the menu bar visible, y_offset=0 puts the bar below it; a negative
        # offset and topmost lift it into the menu bar, on top of the native one.
        # The bar window swallows clicks even where it is transparent, so margin
        # narrows it to a strip around the notch (NOTCH plus room for an item on
        # each side), leaving the app menus and menu extras clickable. The primary
        # display sets the width; q/e stay centred whatever the margin. The width
        # comes from AppKit, since sketchybar --query returns nothing while this
        # file is still loading.
        NOTCH=230
        STRIP=$((NOTCH + 180))
        WIDTH=$(osascript -l JavaScript -e 'ObjC.import("AppKit"); Math.floor($.NSScreen.screens.objectAtIndex(0).frame.size.width)')
        sketchybar --bar height=37 \
                         notch_width=$NOTCH \
                         position=top \
                         padding_left=0 \
                         padding_right=0 \
                         color=0x00000000 \
                         margin=$(( (WIDTH - STRIP) / 2 )) \
                         y_offset=-1 \
                         topmost=on

        # Menu extra styling: no background, white text in the menu bar's font.
        # Icons use the Mono Nerd Font, which keeps each glyph in one centred cell.
        # Sizes and the y_offsets match the native menu text and extras by screenshot.
        sketchybar --default updates=when_shown \
                             icon.font="JetBrainsMono Nerd Font Mono:Regular:18.0" \
                             label.font="SF Pro:Regular:14.0" \
                             icon.y_offset=-2 \
                             label.y_offset=-2 \
                             icon.color=0xffffffff \
                             label.color=0xffffffff \
                             background.drawing=off \
                             icon.padding_left=0 \
                             icon.padding_right=0 \
                             label.padding_left=0 \
                             label.padding_right=0 \
                             padding_left=8 \
                             padding_right=8

        # Active Desktop (native macOS Spaces, which modules/amethyst.nix tiles).
        # SketchyBar's space items track the active Desktop per display, so only the
        # selected one draws and each display shows its own. updates=on: a hidden
        # item must still run its script to reappear.
        for sid in 1 2 3 4 5 6 7 8 9 10; do
          sketchybar --add space space.$sid q \
                     --set space.$sid \
                           space=$sid \
                           updates=on \
                           drawing=off \
                           icon.drawing=off \
                           label="$sid" \
                           script="$PLUGIN_DIR/space.sh"
        done

        sketchybar --add item idle_inhibitor e \
                   --set idle_inhibitor update_freq=10 label.drawing=off \
                         click_script="$PLUGIN_DIR/idle_inhibitor.sh toggle" \
                         script="$PLUGIN_DIR/idle_inhibitor.sh"

        sketchybar --update
      '';
    };

    # Runs per Desktop item on space_change (SketchyBar sets $SELECTED).
    "sketchybar/plugins/space.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        if [ "$SELECTED" = "true" ]; then
          sketchybar --set "$NAME" drawing=on
        else
          sketchybar --set "$NAME" drawing=off
        fi
      '';
    };

    # Mirrors waybar's idle_inhibitor: a click toggles a background caffeinate that
    # holds off display/idle sleep (and so the lock screen). It starts deactivated.
    # Like a native menu extra, the state shows in the glyph alone.
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
          sketchybar --set "$NAME" icon="󰅶"
        else
          sketchybar --set "$NAME" icon="󰾪"
        fi
      '';
    };
  };
}
