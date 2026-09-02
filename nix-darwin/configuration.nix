{ pkgs, username, hostname, ... }:

{
  # Enable flakes and other nix features
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

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

  # Nix garbage collection
  nix.gc = {
    automatic = true;
    interval = {
      Weekday = 0;
      Hour = 2;
      Minute = 0;
    };
    options = "--delete-older-than 7d";
  };

  # Nix store optimization
  nix.optimise.automatic = true;

  # Enable Tailscale
  services.tailscale.enable = true;

  # System packages (macOS-compatible CLI tools).
  # cbonsai/cmatrix live in ../modules/packages.nix now - they are cross-platform
  # and come in through Home Manager on both Linux and macOS.
  environment.systemPackages = with pkgs; [
    tree
    terminaltexteffects
  ];

  # macOS GUI tools
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall";
    };
    casks = [
      "ghostty"
      "brave-browser"
      "zen-browser"
      "obsidian"
      "nextcloud"
      "libreoffice"
      "signal"
      "localsend"
      "vlc"
      "vscodium"
      # Launcher; configured declaratively in ../modules/raycast.nix.
      # NOTE: raycast is set to ⌘Space, which collides with Spotlight. Free it
      # manually: System Settings → Keyboard → Keyboard Shortcuts → Spotlight →
      # uncheck "Show Spotlight search" (fragile to automate from nix).
      "raycast"
    ];
  };

  # macOS system defaults
  system.defaults = {
    dock.autohide = true;
    finder.AppleShowAllExtensions = true;
    NSGlobalDomain.AppleShowAllExtensions = true;

    # Catppuccin-ish appearance (macOS can't be fully re-skinned; this approximates it)
    NSGlobalDomain.AppleInterfaceStyle = "Dark"; # force Dark mode

    # AppleAccentColor/AppleHighlightColor have no typed option in this nix-darwin rev,
    # so write them out-of-band via CustomUserPreferences (passed straight to `defaults`).
    #
    # These stay literal rather than reading ../modules/palette.nix: that palette is a
    # Home Manager module arg, and macOS wants 0-1 floats rather than hex. Keep the
    # value below in sync with `mauve` there by hand.
    CustomUserPreferences.NSGlobalDomain = {
      AppleAccentColor = 5; # Purple accent, closest to Catppuccin mauve/lavender
      AppleHighlightColor = "0.796078 0.650980 0.968627 Purple"; # Mocha mauve #cba6f7, see ../modules/palette.nix
    };
  };

  # SSH hardening (sshd itself is started by toggling System Settings → General → Sharing → Remote Login)
  environment.etc."ssh/sshd_config.d/100-nix-darwin.conf".text = ''
    PasswordAuthentication no
  '';

  # Required for nix-darwin
  system.stateVersion = 6;
}
