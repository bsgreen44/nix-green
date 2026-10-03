{ pkgs, lib, ... }:
# Raycast is a macOS productivity launcher. (Launcher alongside Spotlight)

lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  targets.darwin.defaults."com.raycast.macos" = {
    # Global hotkey -> Option+Space (49 = Space keycode), mirroring hyprland.lua's
    # `mod + SPACE` launcher (mod is Alt on macOS, see modules/aerospace.nix).
    # Cmd+Space stays with Spotlight.
    raycastGlobalHotkey = "Option-49";

    # Compact launcher window, matching hyprland's tight/minimal feel.
    raycastPreferredWindowMode = "compact";
    raycastAppearance = "dark";

    # Keep the menubar tidy (mirrors dock.autohide intent).
    "NSStatusItem Visible raycastIcon" = false;
  };
}
