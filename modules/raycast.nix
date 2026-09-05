{ pkgs, lib, ... }:

lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  targets.darwin.defaults."com.raycast.macos" = {
    # Global hotkey → ⌘Space (49 = Space keycode). Replaces Spotlight - see the
    # note by the raycast cask in nix-darwin/configuration.nix about freeing it.
    raycastGlobalHotkey = "Command-49";

    # Compact launcher window, matching hyprland's tight/minimal feel.
    raycastPreferredWindowMode = "compact";
    raycastAppearance = "dark";

    # Keep the menubar tidy (mirrors dock.autohide intent).
    "NSStatusItem Visible raycastIcon" = false;
  };
}
