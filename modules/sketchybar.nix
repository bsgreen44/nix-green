# SketchyBar - a small extension of the native macOS menu bar, not a status bar of
# its own. The menu bar already shows the clock, battery, volume, Wi-Fi and
# Bluetooth, so SketchyBar adds only what macOS lacks, styled like a native menu
# extra (no background, white SF Pro text) and placed against the notch: the
# active Desktop number left of it, and a screen-awake (caffeinate) toggle right
# of it. The system is forced to Dark mode (nix-darwin/configuration.nix), so the
# menu bar text is always white. SF Pro comes from the font-sf-pro cask there.
#
# One SketchyBar instance runs per display, because the bar's margin (which
# narrows it to the strip around the notch) is a single value shared by every
# display. A margin sized for a wide display exceeds half of a narrower one, and
# a bar window created with that negative width draws as an opaque white block.
# An instance takes its name from argv[0] and talks over a port of that name, so
# each one is a symlink to sketchybar: `sketchybar` draws on display 1,
# `sketchybarN` on display N, and plugins address their own instance as
# $BAR_NAME. An instance whose display isn't connected draws nothing.
#
# darwin-only; guarded so it's inert if ever imported on Linux (like modules/raycast.nix).
{
  config,
  pkgs,
  lib,
  ...
}:
let
  # Display arrangement ids covered: the built-in panel plus two external monitors.
  displays = [ 1 2 3 ];
  barName = index: if index == 1 then "sketchybar" else "sketchybar${toString index}";
  barNames = lib.concatMapStringsSep " " barName displays;

  bars = pkgs.runCommand "sketchybar-instances" { } ''
    mkdir -p $out/bin
    ${lib.concatMapStringsSep "\n" (
      index: "ln -s ${pkgs.sketchybar}/bin/sketchybar $out/bin/${barName index}"
    ) displays}
  '';
in
lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  home.packages = [ bars ];

  # Keep-alive agents so the bars run at login and restart if they die. Each reads
  # ~/.config/sketchybar/sketchybarrc (written below). PATH covers the instances
  # plus the system tools the plugins call (caffeinate, ps, plutil, ...).
  launchd.agents = lib.listToAttrs (
    map (index: {
      name = barName index;
      value = {
        enable = true;
        config = {
          ProgramArguments = [
            "${bars}/bin/${barName index}"
            "--config"
            "${config.xdg.configHome}/sketchybar/sketchybarrc"
          ];
          KeepAlive = true;
          RunAtLoad = true;
          EnvironmentVariables.PATH = "${bars}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        };
      };
    }) displays
  );

  xdg.configFile = {
    "sketchybar/sketchybarrc" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash

        # --config resolves the store symlink, so $CONFIG_DIR is the store path.
        PLUGIN_DIR="${config.xdg.configHome}/sketchybar/plugins"
        BAR="''${BAR_NAME:-sketchybar}"
        DISPLAY_INDEX="''${BAR#sketchybar}"
        DISPLAY_INDEX="''${DISPLAY_INDEX:-1}"

        # Transparent and as tall as the native menu bar on the notched built-in
        # display, on this instance's display only. notch_width is the gap the q/e
        # positions leave for the notch. With the menu bar visible, y_offset=0 puts
        # the bar below it; a negative offset and topmost lift it into the menu bar,
        # on top of the native one. The bar window swallows clicks even where it is
        # transparent, so the bar_margin item below sets margin to narrow it to a
        # strip around the notch, leaving the app menus and menu extras clickable.
        "$BAR" --bar display="$DISPLAY_INDEX" \
                     height=37 \
                     notch_width=230 \
                     position=top \
                     padding_left=0 \
                     padding_right=0 \
                     color=0x00000000 \
                     y_offset=-1 \
                     topmost=on

        # Menu extra styling: no background, white text in the menu bar's font.
        # Icons use the Mono Nerd Font, which keeps each glyph in one centred cell.
        # Sizes and the y_offsets match the native menu text and extras by screenshot.
        "$BAR" --default updates=when_shown \
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
          "$BAR" --add space space.$sid q \
                     --set space.$sid \
                           space=$sid \
                           updates=on \
                           drawing=off \
                           icon.drawing=off \
                           label="$sid" \
                           script="$PLUGIN_DIR/space.sh"
        done

        "$BAR" --add item idle_inhibitor e \
                   --set idle_inhibitor update_freq=10 label.drawing=off \
                         click_script="$PLUGIN_DIR/idle_inhibitor.sh toggle" \
                         script="$PLUGIN_DIR/idle_inhibitor.sh"

        # Sizes the strip to this display's width, at load and whenever displays
        # are connected, removed or rearranged.
        "$BAR" --add item bar_margin q \
               --set bar_margin drawing=off \
                     updates=on \
                     script="$PLUGIN_DIR/bar_margin.sh" \
               --subscribe bar_margin display_change

        "$BAR" --update
      '';
    };

    # Margin that leaves a strip of NOTCH plus room for an item on each side in the
    # middle of this instance's display; q/e stay centred whatever the margin.
    "sketchybar/plugins/bar_margin.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        STRIP=$((230 + 180))
        index="''${BAR_NAME#sketchybar}"
        index="''${index:-1}"

        displays=$("$BAR_NAME" --query displays)
        i=0
        while id=$(plutil -extract "$i.arrangement-id" raw -o - - <<<"$displays" 2>/dev/null); do
          if [ "$id" = "$index" ]; then
            width=$(plutil -extract "$i.frame.w" raw -o - - <<<"$displays")
            "$BAR_NAME" --bar margin=$(( (''${width%.*} - STRIP) / 2 ))
          fi
          i=$((i + 1))
        done
      '';
    };

    # Runs per Desktop item on space_change (SketchyBar sets $SELECTED).
    "sketchybar/plugins/space.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        if [ "$SELECTED" = "true" ]; then
          "$BAR_NAME" --set "$NAME" drawing=on
        else
          "$BAR_NAME" --set "$NAME" drawing=off
        fi
      '';
    };

    # Mirrors waybar's idle_inhibitor: a click toggles a background caffeinate that
    # holds off display/idle sleep (and so the lock screen). It starts deactivated.
    # Like a native menu extra, the state shows in the glyph alone. A toggle updates
    # the glyph on every display's instance, not just the one clicked.
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
          icon="󰅶"
        else
          icon="󰾪"
        fi

        if [ "$1" = "toggle" ]; then
          for bar in ${barNames}; do
            "$bar" --set "$NAME" icon="$icon" 2>/dev/null
          done
        else
          "$BAR_NAME" --set "$NAME" icon="$icon"
        fi
      '';
    };
  };
}
