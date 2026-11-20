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
      "font-sf-pro" # menu bar font for ../modules/sketchybar.nix
      "tailscale-app"
      "handy"
      "stats" # menu bar system monitor
    ];
  };

  # macOS system defaults
  system.defaults = {
    dock.autohide = true;
    finder.AppleShowAllExtensions = true;
    # Desktops are native: 3-finger swipe switches them, and keep them in a
    # fixed order instead of most recent use.
    trackpad.TrackpadThreeFingerHorizSwipeGesture = 2;
    dock.mru-spaces = false;
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      # _HIHideMenuBar = true;
      # Ctrl+Cmd+drag anywhere in a window moves it, like SUPER+drag on Hyprland
      NSWindowShouldDragOnGesture = true;
    };

    # Native window tiling; keyboard shortcuts are in NSUserKeyEquivalents below.
    WindowManager = {
      EnableTilingByEdgeDrag = true; # drag to a side or corner to tile
      EnableTopTilingByEdgeDrag = true; # drag to the top edge to fill
      EnableTilingOptionAccelerator = true; # hold Option while dragging to tile without the delay
      EnableTiledWindowMargins = false; # no gaps between tiled windows
      EnableStandardClickToShowDesktop = false; # clicking the wallpaper doesn't hide all windows
      GloballyEnabled = false; # Stage Manager off
    };
    dock.expose-group-apps = true; # Mission Control groups windows by app

    # Catppuccin-ish appearance (macOS can't be fully re-skinned; this approximates it)
    NSGlobalDomain.AppleInterfaceStyle = "Dark"; # force Dark mode
    CustomUserPreferences.NSGlobalDomain = {
      AppleAccentColor = 5; # Purple accent, closest to Catppuccin mauve/lavender
      AppleHighlightColor = "0.796078 0.650980 0.968627 Purple"; # Mocha mauve #cba6f7, see ../modules/palette.nix
      # Window tiling shortcuts (Window > Move & Resize):
      #   Ctrl+Opt+Arrow         halves (left, right, top, bottom)
      #   Ctrl+Opt+U/I/J/K       quarters (top left, top right, bottom left, bottom right)
      #   Ctrl+Opt+Shift+Arrow   two windows: left & right, right & left, top & bottom, bottom & top
      #   Ctrl+Opt+F / C / R     fill / center / return to previous size
      # Keys are ESC-separated menu paths; values are modifiers (^ ctrl, ~ opt, $ shift)
      # + a lowercase key or an arrow function key (U+F700-F703). Nix strings have no
      # \u escape, hence fromJSON. Apps read these only at launch. The Arrange >
      # Quarters item can't be bound: its title matches the Quarters section heading.
      NSUserKeyEquivalents =
        let
          esc = builtins.fromJSON ''"\u001b"'';
          menu = path: esc + builtins.concatStringsSep esc path;
          mr = item: menu [ "Window" "Move & Resize" item ];
          char = code: builtins.fromJSON ''"\u${code}"'';
          up = char "f700";
          down = char "f701";
          left = char "f702";
          right = char "f703";
          co = key: "^~" + key;
          cos = key: "^~$" + key;
        in
        {
          ${mr "Left"} = co left;
          ${mr "Right"} = co right;
          ${mr "Top"} = co up;
          ${mr "Bottom"} = co down;
          ${mr "Top Left"} = co "u";
          ${mr "Top Right"} = co "i";
          ${mr "Bottom Left"} = co "j";
          ${mr "Bottom Right"} = co "k";
          ${mr "Left & Right"} = cos left;
          ${mr "Right & Left"} = cos right;
          ${mr "Top & Bottom"} = cos up;
          ${mr "Bottom & Top"} = cos down;
          ${mr "Return to Previous Size"} = co "r";
          ${menu [ "Window" "Fill" ]} = co "f";
          ${menu [ "Window" "Center" ]} = co "c";
        };
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
