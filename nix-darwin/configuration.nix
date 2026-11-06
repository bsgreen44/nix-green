{ pkgs, username, hostname, ... }:

{
  imports = [ ./privacy.nix ];

  # Nix itself is installed and managed by Determinate (see README), which runs
  # its own daemon and has flakes on by default. nix-darwin aborts activation if
  # it also tries to manage Nix, and every other `nix.*` option needs this on.
  nix.enable = false;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Set hostname
  networking.hostName = hostname;

  # Set timezone
  time.timeZone = "America/Denver";

  # Enable zsh
  programs.zsh.enable = true;

  # Define user
  users.users.${username} = {
    home = "/Users/${username}";
    shell = pkgs.zsh;
  };

  # User that homebrew and the user-scoped system.defaults apply to
  system.primaryUser = username;

  # Font packages
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  environment.systemPackages = with pkgs; [
    tree
    terminaltexteffects
    brave
    obsidian
    libreoffice-bin
    signal-desktop
    localsend
    vlc-bin
    vscodium
  ];

  environment.variables.HOMEBREW_NO_ANALYTICS = "1";

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall";
      extraEnv.HOMEBREW_NO_ANALYTICS = "1";
    };
    casks = [
      "ghostty"
      "nextcloud"
      "zen-browser"
      "raycast"
      "protonvpn"
      "lm-studio"
      "amethyst" # tiling window manager, configured in ../modules/amethyst.nix
      "font-sf-pro" # menu bar font for ../modules/sketchybar.nix
      "tailscale-app"
    ];
  };

  # macOS system defaults
  system.defaults = {
    dock.autohide = true;
    finder.AppleShowAllExtensions = true;
    # Desktops are native (modules/amethyst.nix tiles each one): 3-finger swipe
    # switches them, and keep them in a fixed order instead of most recent use.
    trackpad.TrackpadThreeFingerHorizSwipeGesture = 2;
    dock.mru-spaces = false;
    # macOS's own edge-drag tiling would fight Amethyst's drag-to-swap.
    WindowManager = {
      EnableTilingByEdgeDrag = false;
      EnableTopTilingByEdgeDrag = false;
      EnableTilingOptionAccelerator = false;
    };
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      # _HIHideMenuBar = true;
    };

    # Catppuccin-ish appearance (macOS can't be fully re-skinned; this approximates it)
    NSGlobalDomain.AppleInterfaceStyle = "Dark"; # force Dark mode
    CustomUserPreferences.NSGlobalDomain = {
      AppleAccentColor = 5; # Purple accent, closest to Catppuccin mauve/lavender
      AppleHighlightColor = "0.796078 0.650980 0.968627 Purple"; # Mocha mauve #cba6f7, see ../modules/palette.nix
    };
  };

  # Don't boot when the lid opens or power connects (%01 = lid only, %02 = power only)
  system.activationScripts.postActivation.text = ''
    /usr/sbin/nvram BootPreference=%00
  '';

  # SSH hardening (sshd itself is started by toggling System Settings → General → Sharing → Remote Login)
  environment.etc."ssh/sshd_config.d/100-nix-darwin.conf".text = ''
    PasswordAuthentication no
  '';

  # Required for nix-darwin
  system.stateVersion = 6;
}
