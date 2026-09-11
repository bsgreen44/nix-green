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
    # Null where the distro (or macOS) ships ghostty; Nix then only writes the
    # config below. Declared in the role registry, not toggled by hand here.
    package = config.green.apps.terminal.package;
    systemd.enable = false;
    settings = {
      background-blur = true;
      theme = "dark:Catppuccin Mocha,light:Catppuccin Latte";
      background-opacity = 0.75;
      window-theme = "dark";
      font-family = "JetBrains Mono";
      font-size = 10;
      #window-decoration = false;
    } // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
      gtk-tabs-location = "hidden"; # GTK-only - Ghostty uses native UI on macOS
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
      tab_bar_style = "hidden"; # matches ghostty gtk-tabs-location = "hidden"
    };
  };
}
