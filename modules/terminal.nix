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
    # Null on a machine whose distro ships ghostty; Nix then only writes the
    # config below. Declared in the role registry, not toggled by hand here.
    package = config.green.apps.terminal.package;
    systemd.enable =false;
    settings = {
      background-blur = true;
      theme = "dark:Catppuccin Mocha,light:Catppuccin Latte";
      background-opacity = 0.75;
      window-theme = "dark";
      font-family = "JetBrains Mono";
      font-size = 10;
      gtk-tabs-location = "hidden";
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
      tab_bar_style = "hidden"; # matches ghostty gtk-tabs-location = "hidden"
    };
  };
}
