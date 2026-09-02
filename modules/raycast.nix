{ pkgs, lib, ... }:

# Raycast launcher - configured similarly to modules/hyprland.nix: a dedicated
# module holding the app's config with Catppuccin theming applied by hand
# (matching the autoEnable = false convention in modules/themes.nix).
#
# Unlike hyprland, Raycast is NOT fully declarative. Most of its state
# (extensions, aliases, quicklinks, snippets, imported themes) lives in an
# opaque per-user store nix cannot manage. Only the writable preferences in the
# com.raycast.macos defaults domain are reproducible, so that's what we set here.
#
# Raycast itself is installed via homebrew cask in nix-darwin/configuration.nix.
# This module is darwin-only; guard it so it's inert if ever imported on Linux
# (consistent with the isLinux/isDarwin conditionals in modules/themes.nix).
#
# Preference-key caveat: Raycast's plist keys are undocumented and drift between
# versions. After first launch, run `defaults read com.raycast.macos` to capture
# the actual keys on the installed version and reconcile them below. A wrong key
# is harmless (ignored), just ineffective.
lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  targets.darwin.defaults."com.raycast.macos" = {
    # Global hotkey → ⌘Space (49 = Space keycode). Replaces Spotlight - see the
    # note by the raycast cask in nix-darwin/configuration.nix about freeing it.
    raycastGlobalHotkey = "Command-49";

    # Compact launcher window, matching hyprland's tight/minimal feel.
    raycastPreferredWindowMode = "compact";

    # Catppuccin Mocha is a dark theme → force dark appearance. The actual
    # palette can't be dropped in via nix (Raycast stores imported themes
    # internally); import "Catppuccin Mocha" once in-app via ray.so/themes or a
    # raycast://theme?... deeplink, the same way hyprland hard-codes its colors.
    raycastAppearance = "dark";

    # Keep the menubar tidy (mirrors dock.autohide intent).
    "NSStatusItem Visible raycastIcon" = false;
  };
}
