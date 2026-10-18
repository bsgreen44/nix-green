{ pkgs, lib, ... }:
# Raycast is a macOS productivity launcher. (Launcher alongside Spotlight)

lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  targets.darwin.defaults."com.raycast.macos" = {
    # Global hotkey -> Cmd+Space (49 = Space keycode). Spotlight's own Cmd+Space
    # shortcut is turned off by hand, see nix-darwin/privacy.nix.
    raycastGlobalHotkey = "Command-49";

    # Compact launcher window, matching hyprland's tight/minimal feel.
    raycastPreferredWindowMode = "compact";
    raycastAppearance = "dark";

    # Keep the menubar tidy (mirrors dock.autohide intent).
    "NSStatusItem Visible raycastIcon" = false;
  };
}
