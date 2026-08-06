{ pkgs, ... }:

{
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

    # brave & vscodium are nix packages on Linux but homebrew casks on macOS,
    # so only theme them through nix on Linux:
    brave.enable = pkgs.stdenv.isLinux;
    vscodium.profiles.default.enable = pkgs.stdenv.isLinux; # follows catppuccin.flavor
  };
}
