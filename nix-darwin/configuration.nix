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
    casks = [
      "brave-browser"
      "obsidian"
      "nextcloud"
      "libreoffice"
      "signal"
      "localsend"
      "vlc"
    ];
  };

  # macOS system defaults
  system.defaults = {
    dock.autohide = true;
    finder.AppleShowAllExtensions = true;
    NSGlobalDomain.AppleShowAllExtensions = true;
  };

  # Enable SSH
  environment.etc."ssh/sshd_config.d/100-nix-darwin.conf".text = ''
    PasswordAuthentication no
  '';

  # Required for nix-darwin
  system.stateVersion = 6;
}
