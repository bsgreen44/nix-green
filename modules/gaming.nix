# NixOS module (not Home Manager): Steam, Proton and game launchers.
# Off unless `gaming = true;` in flake.nix, so low-end machines stay lean.
{ config, pkgs, lib, username, gaming, ... }:

lib.mkIf gaming {
  # Also turns on hardware.graphics.enable32Bit, which Proton needs.
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    protontricks.enable = true;
    # "Steam Big Picture" session in the display manager, running in gamescope.
    gamescopeSession.enable = true;
    # GE-Proton, selectable per game next to Valve's Proton builds, which
    # Steam downloads itself.
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };

  # Micro-compositor for games: upscaling, frame limits, HDR. capSysNice lets it
  # raise its own scheduling priority.
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  # Run a game with `gamemoderun %command%` in Steam's launch options.
  programs.gamemode = {
    enable = true;
    # Hyprland's focused-window rule controls idle inhibition instead of keeping
    # the session awake for the entire lifetime of a background game.
    settings = lib.mkIf config.programs.hyprland.enable {
      general.inhibit_screensaver = 0;
    };
  };
  users.users.${username}.extraGroups = [ "gamemode" ];

  environment.systemPackages = with pkgs; [
    lutris   # Battle.net (World of Warcraft) and other non-Steam games
    mangohud # FPS and frametime overlay: `mangohud %command%`
  ];
}
