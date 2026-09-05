{ pkgs, ... }:

{
  # Supplies the `palette` module argument to the hand-themed programs below.
  imports = [ ./palette.nix ];

  catppuccin = {
    enable = true;
    flavor = "mocha"; # global flavor for all catppuccin-themed apps (e.g. VSCodium)
    autoEnable = false; # do NOT theme everything - many programs are themed by hand
                        # (ghostty, mako, rofi, waybar, starship, neovim, hyprland, hyprlock)

    # Only programs not manually themed elsewhere:
    bat.enable = true;
    btop.enable = true;
    kitty.enable = true;
    opencode.enable = true;
    vscodium.profiles.default.enable = true; # follows catppuccin.flavor
    brave.enable = pkgs.stdenv.hostPlatform.isLinux;
  };
}
