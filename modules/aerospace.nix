{ pkgs, lib, ... }:

# AeroSpace tiling window manager - the macOS analogue of modules/hyprland.nix.
# Chosen over yabai because it needs no SIP changes. Fully declarative via the
# TOML `settings` attrset, run as a login launchd agent.
#
# Mod key is Alt/Option (AeroSpace default), deliberately avoiding ⌘-chords so it
# never collides with Raycast's ⌘Space or macOS system shortcuts. Keybindings
# mirror the intent of modules/hyprland.nix (hjkl focus/move, 1-9 workspaces).
lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  programs.aerospace = {
    enable = true;
    launchd.enable = true; # start at login

    settings = {
      # Match hyprland's gapped, minimal feel (see modules/waybar.nix spacing).
      gaps = {
        inner.horizontal = 8;
        inner.vertical = 8;
        outer.left = 8;
        outer.right = 8;
        outer.top = 8;
        outer.bottom = 8;
      };

      # Default to tiling with an accordion fallback (analogue of dwindle).
      default-root-container-layout = "tiles";
      default-root-container-orientation = "auto";

      # Keep SketchyBar's workspace highlight in sync with focus.
      exec-on-workspace-change = [
        "/bin/bash"
        "-c"
        "sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE"
      ];

      # Never tile Raycast's launcher panel (usually automatic; explicit is safe).
      on-window-detected = [
        {
          "if".app-id = "com.raycast.macos";
          run = [ "layout floating" ];
        }
      ];

      mode.main.binding = {
        # Focus (hjkl, like hyprland).
        alt-h = "focus left";
        alt-j = "focus down";
        alt-k = "focus up";
        alt-l = "focus right";

        # Move window.
        alt-shift-h = "move left";
        alt-shift-j = "move down";
        alt-shift-k = "move up";
        alt-shift-l = "move right";

        # Layout.
        alt-f = "fullscreen";
        alt-shift-space = "layout floating tiling"; # toggle float
        alt-slash = "layout tiles horizontal vertical";
        alt-comma = "layout accordion horizontal vertical";

        # Switch to workspace 1-9.
        alt-1 = "workspace 1";
        alt-2 = "workspace 2";
        alt-3 = "workspace 3";
        alt-4 = "workspace 4";
        alt-5 = "workspace 5";
        alt-6 = "workspace 6";
        alt-7 = "workspace 7";
        alt-8 = "workspace 8";
        alt-9 = "workspace 9";

        # Move focused window to workspace 1-9.
        alt-shift-1 = "move-node-to-workspace 1";
        alt-shift-2 = "move-node-to-workspace 2";
        alt-shift-3 = "move-node-to-workspace 3";
        alt-shift-4 = "move-node-to-workspace 4";
        alt-shift-5 = "move-node-to-workspace 5";
        alt-shift-6 = "move-node-to-workspace 6";
        alt-shift-7 = "move-node-to-workspace 7";
        alt-shift-8 = "move-node-to-workspace 8";
        alt-shift-9 = "move-node-to-workspace 9";
      };
    };
  };
}
