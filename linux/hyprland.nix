## Hyprland desktop on a non-NixOS distro.
##
## Layers the desktop modules on top of ./home.nix, so `.#green` stays CLI-only
## and `.#green-hyprland` is that plus the desktop. Install the compositor with
## the distro's package manager first; Nix only writes the config.
{ pkgs, username, ... }:
{
  imports = [
    ./home.nix
    ../modules/hyprland.nix
    ../modules/hypridle.nix
    ../modules/hyprlock.nix
    ../modules/waybar.nix
    ../modules/rofi.nix
    ../modules/mako.nix
    ../modules/screensaver.nix
  ];

  _module.args = {
    wallpaper = "/home/${username}/nix-green/wallpapers/catppuccin_mocha_japanese_wallpaper_8k.png";
    hidpi = false;   # set true on 2k/4k laptop panels

    # No flake input: hyprland.nix then nulls package/portalPackage, so the
    # compositor comes from the distro (COPR) and Nix only writes the config.
    hyprland = null;
  };

  # On NixOS these come from configuration.nix, which this path never evaluates.
  home.packages = with pkgs; [
    terminaltexteffects  # `tte`, used by screensaver.nix
    hyprland-qtutils     # hyprland-dialog etc; distro build doesn't ship it
    hyprmon              # monitor manager; rofi.nix has a desktop entry for it
  ];

  # Let a new lock client replace a dead one; without it a crashed hyprlock
  # leaves the session stuck on "Broken lockscreen app". Off by default upstream
  # since it weakens the ext-session-lock guarantee, so NixOS keeps the default.
  # extraConfig is lib.types.lines, so this appends to hyprland.nix's block.
  wayland.windowManager.hyprland.extraConfig = ''
    hl.config({ misc = { allow_session_lock_restore = true } })
  '';

  # Distro hyprlock: pam_unix needs the setuid unix_chkpwd helper to read
  # /etc/shadow, and the Nix copy isn't setuid here, so the nixpkgs build can
  # never authenticate. Config is still generated - same pattern as ghostty.
  programs.hyprlock.package = null;
}
