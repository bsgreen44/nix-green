{ config, pkgs, lib, ... }:

# AeroSpace tiling window manager - the macOS analogue of modules/hyprland.nix.
# Chosen over yabai because it needs no SIP changes. Fully declarative via the
# TOML `settings` attrset, run as a login launchd agent.
#
# Mod key is Alt/Option (Hyprland's SUPER maps to alt), deliberately avoiding
# command-chords so it never collides with macOS system shortcuts. Keybindings
# mirror modules/hyprland.nix / dotfiles/.config/hypr/hyprland.lua.
lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  programs.aerospace = {
    enable = true;
    launchd.enable = true; # start at login

    settings = {
      # Version 2 stops AeroSpace inferring persistent workspaces from the bindings
      # (version 1, the default when omitted, is deprecated). With no
      # persistent-workspaces set, empty workspaces vanish like Hyprland's.
      config-version = 2;

      # Match hyprland.lua's gaps (inner 3, outer 7).
      gaps = {
        inner.horizontal = 3;
        inner.vertical = 3;
        outer.left = 7;
        outer.right = 7;
        outer.top = 7;
        outer.bottom = 7;
      };

      # Default to tiling with an accordion fallback (analogue of dwindle).
      default-root-container-layout = "tiles";
      default-root-container-orientation = "auto";

      # Keep SketchyBar's workspaces in sync. on-focus-changed also catches a window
      # being moved to or closed on another workspace, which changes which
      # workspaces are in use. Store paths: AeroSpace's launchd PATH lacks the
      # Home Manager profile.
      exec-on-workspace-change = [
        "/bin/bash"
        "-c"
        "${pkgs.sketchybar}/bin/sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE"
      ];
      on-focus-changed = [
        "exec-and-forget ${pkgs.sketchybar}/bin/sketchybar --trigger aerospace_workspace_change"
      ];

      # Never tile Raycast's launcher panel (usually automatic; explicit is safe).
      on-window-detected = [
        {
          "if".app-id = "com.raycast.macos";
          run = [ "layout floating" ];
        }
        # Mirrors hyprland.lua's float-title rule: terminals opened with
        # --title=float (btop etc.) float.
        {
          "if".window-title-regex-substring = "float";
          run = [ "layout floating" ];
        }
      ];

      mode.main.binding = {
        # Application launchers (hyprland.lua "Application launchers"). Terminal
        # tools use absolute paths: Ghostty runs them without a login shell, so the
        # Home Manager profile is not on PATH.
        alt-enter = "exec-and-forget open -na Ghostty";
        alt-shift-b = "exec-and-forget open -a \"Brave Browser\"";
        alt-shift-f = "exec-and-forget open -a Finder";
        alt-shift-o = "exec-and-forget open -a Obsidian";
        alt-shift-v = "exec-and-forget open -a VSCodium";
        alt-shift-m = "exec-and-forget open -na Ghostty --args --title=float -e ${config.home.profileDirectory}/bin/btop";
        alt-shift-n = "exec-and-forget open -na Ghostty --args -e ${config.home.profileDirectory}/bin/nvim";
        alt-shift-g = "exec-and-forget open -na Ghostty --args -e ${config.home.profileDirectory}/bin/lazygit";
        alt-shift-a = "exec-and-forget open -na Ghostty --args -e ${config.home.profileDirectory}/bin/opencode";

        # Window and session.
        alt-q = "close";
        alt-t = "layout floating tiling"; # toggle float
        alt-f = "fullscreen";
        alt-u = "layout tiles horizontal vertical"; # togglesplit
        alt-l = "exec-and-forget pmset displaysleepnow"; # lock (needs "require password" on wake)
        alt-shift-z = "exec-and-forget open -a ScreenSaverEngine"; # screensaver
        alt-shift-s = "exec-and-forget screencapture -ic"; # region screenshot to clipboard
        alt-shift-space = "exec-and-forget ${pkgs.sketchybar}/bin/sketchybar --bar hidden=toggle"; # toggle bar

        # Focus and swap with the arrow keys.
        alt-left = "focus left";
        alt-down = "focus down";
        alt-up = "focus up";
        alt-right = "focus right";
        alt-shift-left = "move left";
        alt-shift-down = "move down";
        alt-shift-up = "move up";
        alt-shift-right = "move right";

        # Scrolling-layout binds (J/K move across columns, comma/period resize).
        alt-j = "focus left";
        alt-k = "focus right";
        alt-shift-j = "move left";
        alt-shift-k = "move right";
        alt-comma = "resize width -100";
        alt-period = "resize width +100";

        # Resize the active window (hyprland.lua mod + minus/equal).
        alt-minus = "resize width -100";
        alt-equal = "resize width +100";
        alt-shift-minus = "resize height -100";
        alt-shift-equal = "resize height +100";

        # Switch to workspace 1-10 (0 is 10, like hyprland.lua).
        alt-1 = "workspace 1";
        alt-2 = "workspace 2";
        alt-3 = "workspace 3";
        alt-4 = "workspace 4";
        alt-5 = "workspace 5";
        alt-6 = "workspace 6";
        alt-7 = "workspace 7";
        alt-8 = "workspace 8";
        alt-9 = "workspace 9";
        alt-0 = "workspace 10";

        # Move focused window to workspace 1-10.
        alt-shift-1 = "move-node-to-workspace 1";
        alt-shift-2 = "move-node-to-workspace 2";
        alt-shift-3 = "move-node-to-workspace 3";
        alt-shift-4 = "move-node-to-workspace 4";
        alt-shift-5 = "move-node-to-workspace 5";
        alt-shift-6 = "move-node-to-workspace 6";
        alt-shift-7 = "move-node-to-workspace 7";
        alt-shift-8 = "move-node-to-workspace 8";
        alt-shift-9 = "move-node-to-workspace 9";
        alt-shift-0 = "move-node-to-workspace 10";

        # Next workspace (hyprland.lua mod + TAB).
        alt-tab = "workspace --wrap-around next";

        # Hyprland binds with no macOS analogue, intentionally not mapped:
        #  - tsui (Shift+T): Linux-only package, not installed on macOS
        #  - pseudo (P), exit (Shift+Esc), powermenu (Esc), keybind help (Shift+H)
        #  - mako dismiss (N, Ctrl+N): macOS has its own notification centre
        #  - ALT+TAB window cycling: collides with mod+Tab under the Alt mod
        #    (macOS Cmd+Tab covers it)
        #  - media/brightness keys: native on macOS
        #  - launcher (Space): Raycast owns alt-space (modules/raycast.nix), so it is
        #    deliberately left unbound here
        #  - clipboard history (Ctrl+V): Raycast's per-command hotkeys are not
        #    declarative, so set Alt+Ctrl+V by hand in Raycast's Clipboard History
      };
    };
  };
}
