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

  # Raycast script commands. Raycast keeps hotkeys in its encrypted database, so
  # this directory is added and the hotkey (Shift+Option+Return) set once by hand:
  # Settings > Extensions > + > Add Script Directory.
  home.file.".config/raycast/script-commands/new-ghostty-window.sh" = {
    executable = true;
    text = ''
      #!/bin/bash
      # @raycast.schemaVersion 1
      # @raycast.title New Ghostty Window
      # @raycast.mode silent
      # @raycast.packageName Ghostty
      # @raycast.icon /Applications/Ghostty.app/Contents/Resources/Ghostty.icns

      # Ghostty's AppleScript `new window` opens on the current desktop, where
      # activating the app first would switch to a desktop that has a Ghostty
      # window. A cold launch opens its own first window, so only launch then.
      osascript <<'EOF'
      if application "Ghostty" is running then
        tell application "Ghostty" to activate window (new window)
      else
        tell application "Ghostty" to activate
      end if
      EOF
    '';
  };
}
