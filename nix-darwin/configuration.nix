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

  # System packages (macOS-compatible CLI tools)
  environment.systemPackages = with pkgs; [
    tree
    terminaltexteffects
    cbonsai
    cmatrix
  ];

  # macOS GUI tools
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall";
    };
    casks = [
      "brave-browser"
      "zen-browser"
      "obsidian"
      "nextcloud"
      "libreoffice"
      "signal"
      "localsend"
      "vlc"
      "vscodium"
    ];
  };

  # macOS system defaults
  system.defaults = {
    dock.autohide = true;
    finder.AppleShowAllExtensions = true;
    NSGlobalDomain.AppleShowAllExtensions = true;

    # Catppuccin-ish appearance (macOS can't be fully re-skinned; this approximates it)
    NSGlobalDomain.AppleInterfaceStyle = "Dark"; # force Dark mode
    NSGlobalDomain.AppleAccentColor = 5; # Purple accent, closest to Catppuccin mauve/lavender
    NSGlobalDomain.AppleHighlightColor = "0.796078 0.650980 0.968627 Purple"; # selection highlight in Mocha mauve (#cba6f7)
  };

  # SSH hardening (sshd itself is started by toggling System Settings → General → Sharing → Remote Login)
  environment.etc."ssh/sshd_config.d/100-nix-darwin.conf".text = ''
    PasswordAuthentication no
  '';

  # Required for nix-darwin
  system.stateVersion = 6;
}
