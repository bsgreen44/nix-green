{ pkgs, lib, config, ghostty, ... }:

{
  # The ghostty flake package on Linux. Null on macOS, where ghostty has no Nix
  # build and comes from the homebrew cask in nix-darwin/configuration.nix, and
  # on any machine whose system-apps file nulls it. Lazy, so the flake package is
  # never forced where something else provides the binary.
  green.apps.terminal.package = lib.mkDefault (
    if pkgs.stdenv.hostPlatform.isLinux
    then ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default
    else null
  );

  # ghostty config
  programs.ghostty = {
    enable = true;
    enableBashIntegration = false;
    package = config.green.apps.terminal.package;
    # The package's desktop entry is DBusActivatable and its D-Bus service
    # names app-com.mitchellh.ghostty.service, so without this unit launching
    # Ghostty from a menu or krunner fails. A distro or homebrew ghostty
    # (package = null) brings its own launcher, and the module asserts a
    # package for this anyway.
    systemd.enable = config.green.apps.terminal.package != null;
    settings = {
      background-blur = true;
      theme = "dark:Catppuccin Mocha,light:Catppuccin Latte";
      background-opacity = 0.75;
      window-theme = "dark";
      font-family = "JetBrainsMono Nerd Font Mono";
      font-size = 10;
      #window-decoration = false;
    } // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
      window-show-tab-bar = "never"; # GTK-only - Ghostty uses native UI on macOS
    };
  };

  # kitty config - mirrors the ghostty settings above
  programs.kitty = {
    enable = true;
    shellIntegration.enableBashIntegration = false; # matches ghostty enableBashIntegration = false
    font = {
      name = "JetBrainsMono Nerd Font Mono";
      size = 10;
    };
    settings = {
      background_opacity = "0.9";
      tab_bar_style = "hidden"; # matches ghostty window-show-tab-bar = "never"
    };
  };
}
