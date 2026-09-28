{ pkgs, lib, config, ghostty, ... }:

{
  # The nixpkgs/flake ghostty, used unless a machine's system-apps file nulls it.
  # Lazy, so it is never forced where the distro provides the binary instead.
  green.apps.terminal.package =
    lib.mkDefault ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # ghostty config
  programs.ghostty = {
    enable = true;
    enableBashIntegration = false;
    package = config.green.apps.terminal.package;
    # The package's desktop entry is DBusActivatable and its D-Bus service
    # names app-com.mitchellh.ghostty.service, so without this unit launching
    # Ghostty from a menu or krunner fails. A distro ghostty (package = null)
    # brings its own unit, and the module asserts a package for this anyway.
    systemd.enable = config.green.apps.terminal.package != null;
    settings = {
      background-blur = true;
      theme = "dark:Catppuccin Mocha,light:Catppuccin Latte";
      background-opacity = 0.75;
      window-theme = "dark";
      font-family = "JetBrainsMono Nerd Font Mono";
      font-size = 10;
      window-show-tab-bar = "never";
      #window-decoration = false;
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
