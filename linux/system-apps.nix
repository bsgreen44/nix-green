## What this machine's distro already provides.
##
## The only file to edit when moving to another distro - everything else is
## distro-neutral and falls back to the nixpkgs defaults in modules/apps.nix.
## Run `scripts/detect-system-apps.sh` to regenerate this block, then check the
## reported app_ids against `hyprctl clients -j | jq -r '.[].class'`.
##
## Empty this attrset out (leave `green.apps = { };`) to have Nix install
## everything itself again.
{ ... }:
{
  # Fedora 44 KDE Plasma.
  green.apps = {
    # ghostty comes from the Fedora package; Nix only writes ~/.config/ghostty/config.
    terminal = { package = null; };

    fileManager = {
      command = "dolphin";
      class = "org.kde.dolphin";
      desktop = "org.kde.dolphin.desktop";
    };

    calculator = {
      command = "kcalc";
      class = "org.kde.kcalc";
      desktop = "org.kde.kcalc.desktop";
      package = null; # replaces nixpkgs gnome-calculator
    };

    imageViewer = {
      command = "gwenview";
      class = "org.kde.gwenview";
      desktop = "org.kde.gwenview.desktop";
      package = null; # replaces nixpkgs swayimg
    };

    archiver = {
      command = "ark";
      class = "org.kde.ark";
      desktop = "org.kde.ark.desktop";
    };

    pdfViewer = {
      command = "okular";
      class = "org.kde.okular";
      desktop = "org.kde.okular.desktop";
    };
  };
}
