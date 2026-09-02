{ pkgs, lib, ghostty, ... }:

{
  # ghostty config
  programs.ghostty = {
    enable = true;
    enableBashIntegration = false;
    # On Linux use the ghostty flake's package; on macOS ghostty has no Nix build
    # (installed via the Homebrew cask instead), so null = manage config only.
    package =
      if pkgs.stdenv.hostPlatform.isLinux
      then ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default
      else null;
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
