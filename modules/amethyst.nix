{ config, pkgs, lib, ... }:

# Amethyst tiling window manager. Replaced AeroSpace (modules/aerospace.nix, no
# longer imported) because AeroSpace's virtual workspaces don't coexist with
# macOS Desktops; Amethyst tiles each native Desktop separately, so the native
# 3-finger swipe, Mission Control and Ctrl+arrow keep working. Installed as a
# Homebrew cask (nix-darwin/configuration.nix); it needs Accessibility.
#
# Tiling only: Amethyst can't launch apps or run commands, so AeroSpace's
# launcher/action binds were dropped (Raycast on alt-space launches apps).
#
# Mod key is Alt/Option like AeroSpace (mod1 = alt, mod2 = alt+shift); the binds
# follow modules/aerospace.nix where Amethyst has an equivalent. Amethyst orders
# windows in a ring, so left/right map to counter-clockwise/clockwise.
#
# Amethyst reads ~/.amethyst.yml only at launch: quit and reopen it to apply
# changes. If a change still doesn't show, quit it, run
# `defaults delete com.amethyst.Amethyst` and reopen; GUI preferences can shadow
# the file (https://github.com/ianyh/Amethyst/issues/1419).
#
# darwin-only; guarded so it's inert if ever imported on Linux (like modules/raycast.nix).
let
  bind = mod: key: { inherit mod key; };
in
lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  # Start at login (the cask installs to /Applications).
  launchd.agents.amethyst = {
    enable = true;
    config = {
      ProgramArguments = [ "/usr/bin/open" "-a" "Amethyst" ];
      RunAtLoad = true;
    };
  };

  # Hyprland's dwindle as a custom layout (key = file name). Amethyst's own bsp
  # keeps hidden apps' windows (Cmd+H) in its split tree, leaving empty tiles, so
  # a new window only got half the screen. This one recomputes every frame from
  # the visible windows: each takes half the space left, split along its longer
  # side (dwindle with focus on the newest window). Amethyst adds the gaps.
  # alt-minus/equal resize the first split; the swap binds reorder the spiral.
  home.file."Library/Application Support/Amethyst/Layouts/dwindle.js".text = ''
    function layout() {
        return {
            name: "Dwindle",
            initialState: { ratio: 0.5 },
            commands: {
                shrinkMain: { description: "Shrink first split", updateState: (state) => ({ ...state, ratio: Math.max(0.1, state.ratio - 0.05) }) },
                expandMain: { description: "Expand first split", updateState: (state) => ({ ...state, ratio: Math.min(0.9, state.ratio + 0.05) }) }
            },
            getFrameAssignments: (windows, screenFrame, state) => {
                let rest = { x: screenFrame.x, y: screenFrame.y, width: screenFrame.width, height: screenFrame.height };
                const frames = {};
                windows.forEach((window, index) => {
                    if (index === windows.length - 1) {
                        frames[window.id] = rest;
                        return;
                    }
                    const ratio = index === 0 ? state.ratio : 0.5;
                    if (rest.width >= rest.height) {
                        const width = rest.width * ratio;
                        frames[window.id] = { x: rest.x, y: rest.y, width: width, height: rest.height };
                        rest = { x: rest.x + width, y: rest.y, width: rest.width - width, height: rest.height };
                    } else {
                        const height = rest.height * ratio;
                        frames[window.id] = { x: rest.x, y: rest.y, width: rest.width, height: height };
                        rest = { x: rest.x, y: rest.y + height, width: rest.width, height: rest.height - height };
                    }
                });
                return frames;
            }
        };
    }
  '';

  # JSON is valid YAML.
  home.file.".amethyst.yml".text = builtins.toJSON {
    mod1 = [ "option" ];
    mod2 = [ "option" "shift" ];
    mod3 = [ "option" "control" ];

    # Dwindle only (above); alt-f / alt-u toggle fullscreen.
    layouts = [ "dwindle" "fullscreen" ];

    # Match AeroSpace/Hyprland gaps (inner 3, outer 7). Margins go between and
    # around windows, so the screen padding adds the remaining 4 at the edges.
    window-margins = true;
    window-margin-size = 3;
    screen-padding-left = 4;
    screen-padding-right = 4;
    screen-padding-top = 4;
    screen-padding-bottom = 4;

    # SafariPlatformSupport.Helper owns the invisible password/passkey AutoFill
    # panel (and a "Privacy & Security" window); float it so it never takes a tile.
    floating = [ "com.raycast.macos" "com.apple.SafariPlatformSupport.Helper" ];
    floating-is-blacklist = true;

    enables-layout-hud-on-space-change = false;

    # Focus and swap with the arrow keys.
    focus-ccw = bind "mod1" "left";
    focus-cw = bind "mod1" "right";
    focus-main = bind "mod1" "up";
    swap-ccw = bind "mod2" "left";
    swap-cw = bind "mod2" "right";
    swap-main = bind "mod2" "up";

    # Resize the first dwindle split (aerospace.nix mod + minus/equal).
    shrink-main = bind "mod1" "-";
    expand-main = bind "mod1" "=";

    # Window and layout.
    toggle-float = bind "mod1" "t";
    cycle-layout = bind "mod1" "u";
    select-fullscreen-layout = bind "mod1" "f";
    toggle-tiling = bind "mod2" "t";
    reevaluate-windows = bind "mod2" "r";

    # Move the focused window to the Desktop left/right (Ctrl+arrow switches).
    throw-space-left = bind "mod3" "left";
    throw-space-right = bind "mod3" "right";

    # Free up Amethyst's default binds that are not mapped above (it otherwise
    # keeps its alt+shift defaults, which collide with mod2).
    cycle-layout-backward = false;
    increase-main = false; # dwindle has no main-pane count
    decrease-main = false;
    select-tall-layout = false;
    select-wide-layout = false;
    select-column-layout = false;
    focus-screen-ccw = false;
    focus-screen-cw = false;
    swap-screen-ccw = false;
    swap-screen-cw = false;
    display-current-layout = false;
    toggle-focus-follows-mouse = false;
    relaunch-amethyst = false;
  };
}
