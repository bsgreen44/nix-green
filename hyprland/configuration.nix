{
  pkgs,
  username,
  hostname,
  hyprland,
  ...
}:

{

  # Enable greetd
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd start-hyprland";
        user = username;
      };
    };
  };

  # Enable Hyprland
  programs.hyprland = {
    enable = true;
    package = hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
  };

  # Enable GNOME Keyring and set to auto-unlock
  security.pam.services.greetd.enableGnomeKeyring = true;

  # Required services for Hyprland
  services.dbus.enable = true;
  hardware.graphics.enable = true;

  # GUI file manager
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin
      thunar-volman
    ];
  };
  services.gvfs.enable = true; # Mount, trash, and other functionalities
  services.tumbler.enable = true; # Thumbnail support for images

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    bluetui
    gnome-disk-utility
    hyprmon
    xarchiver
    unzip
  ];
}
