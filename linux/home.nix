{ pkgs, username, ... }:
{
  imports = [
    ../modules/packages.nix
    ../modules/terminal.nix
    ../modules/shells.nix
    ../modules/starship.nix
    ../modules/neovim.nix
    ../modules/themes.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "25.11";

  # On NixOS this comes from configuration.nix, which this path never evaluates.
  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono  # ghostty and kitty both ask for JetBrains Mono
  ];

  # Required for Home Manager-installed fonts to be found by fontconfig.
  fonts.fontconfig.enable = true;

  # Replaces configuration.nix's programs.ssh.startAgent, which this path never
  # evaluates; without it SSH_AUTH_SOCK is unset.
  services.ssh-agent.enable = true;

  # Running on a non-NixOS distro (Fedora/Ubuntu/Arch/etc.): source session vars
  # and expose Nix-installed apps' desktop entries/icons via XDG_DATA_DIRS.
  targets.genericLinux.enable = true;

  # Standalone HM manages its own nixpkgs config (no NixOS layer to inherit from).
  nixpkgs.config.allowUnfree = true;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
