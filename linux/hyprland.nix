## Hyprland desktop on a non-NixOS distro.
##
## Layers the desktop modules on top of ./home.nix, so `.#green` stays CLI-only
## and `.#green-hyprland` is that plus the desktop. Install the compositor with
## the distro's package manager first; Nix only writes the config.
{ pkgs, lib, config, username, ... }:
{
  imports = [
    ./home.nix
    ../modules/hyprland.nix
    ../modules/hypridle.nix
    ../modules/hyprlock.nix
    ../modules/waybar.nix
    ../modules/rofi.nix
    ../modules/mako.nix
    ../modules/swayosd.nix
    ../modules/screensaver.nix
  ];

  _module.args = {
    wallpaper = "/home/${username}/nix-green/wallpapers/catppuccin_mocha_japanese_wallpaper_8k.png";
    hidpi = false;   # set true on 2k/4k laptop panels

    # No flake input: hyprland.nix then nulls package/portalPackage, so the
    # compositor comes from the distro (COPR) and Nix only writes the config.
    hyprland = null;
  };

  # Idle screensaver. false makes hypridle's 3-minute timeout lock the session
  # directly; SUPER + SHIFT + Z still launches the screensaver by hand.
  green.screensaver.enable = false;

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

  # Default applications, derived from the role registry. Only roles that declare
  # a .desktop name contribute, so a machine that declares none (or runs on NixOS,
  # which never evaluates this file) gets no mimeapps.list at all. Without this
  # the archiver and PDF roles would have no consumer and KDE would keep guessing.
  xdg.mimeApps =
    let
      mimesByRole = {
        fileManager = [ "inode/directory" ];
        pdfViewer = [ "application/pdf" ];
        archiver = [
          "application/zip"
          "application/gzip"
          "application/x-tar"
          "application/x-compressed-tar"     # .tar.gz, what file managers report
          "application/x-bzip-compressed-tar"
          "application/x-xz-compressed-tar"
          "application/x-7z-compressed"
          "application/vnd.rar"
        ];
        imageViewer = [
          "image/png"
          "image/jpeg"
          "image/gif"
          "image/webp"
        ];
      };
      defaults = lib.concatMapAttrs
        (role: mimes:
          let desktop = config.green.apps.${role}.desktop or null;
          in lib.optionalAttrs (desktop != null) (lib.genAttrs mimes (_: desktop)))
        mimesByRole;
      # Enabling xdg.mimeApps makes Home Manager own ~/.config/mimeapps.list
      # outright, so anything that was in the unmanaged file and is not declared
      # here is dropped. These were in it; the browser is spelled out rather than
      # taken from the registry, matching hyprland.nix's literal `browser` local.
      browser = {
        "x-scheme-handler/http" = "brave-browser.desktop";
        "x-scheme-handler/https" = "brave-browser.desktop";
        "text/html" = "brave-browser.desktop";
      };
    in
    lib.mkIf (defaults != { }) {
      enable = true;
      associations.added = browser;
      defaultApplications = defaults // browser // {
        "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
      };
    };
}
