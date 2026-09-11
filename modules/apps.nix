{ pkgs, lib, ... }:

## Role registry: which command fills each app role, and whether Nix installs it.
##
## Consumers (hyprland, rofi, waybar, screensaver, terminal) read `config.green.apps`
## instead of hardcoding a name, so a machine whose distro already ships an app can
## point the role at that binary and stop Nix installing a second copy. The defaults
## below are what NixOS gets; per-machine overrides live in one file next to the
## profile that needs them (see linux/system-apps.nix).
##
## Not covered: hyprland.nix's `terminal`/`browser` Lua locals (modules/hyprland.nix
## L91-95) are deliberately literal, so changing `terminal.command` here retargets
## waybar/rofi/the screensaver but NOT Super+Return - edit that local by hand.
let
  role = lib.types.submodule ({ config, ... }: {
    options = {
      command = lib.mkOption {
        type = lib.types.str;
        description = "Command to run. Resolved via $PATH, not a store path.";
      };

      class = lib.mkOption {
        type = lib.types.str;
        default = config.command;
        description = "Wayland app_id, for window rules. `hyprctl clients -j` reports it.";
      };

      desktop = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          .desktop file name, used to register the app as a mime handler. Null means
          the role contributes no default-application entry.
        '';
      };

      package = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        default = null;
        description = ''
          Package Nix installs for this role. Null means the distro provides the
          binary and Nix installs nothing - the same idiom as programs.ghostty.package
          and wayland.windowManager.hyprland.package elsewhere in this repo.
        '';
      };
    };
  });
in
{
  options.green.apps = lib.mkOption {
    type = lib.types.attrsOf role;
    default = { };
    description = "App roles, keyed by role name.";
  };

  # mkDefault has to sit on each leaf, not on the attrset: a mkDefault covering the
  # whole definition would be dropped outright once any other module defines
  # green.apps, taking the roles that module never mentioned with it.
  config.green.apps = lib.mapAttrs (_: lib.mapAttrs (_: lib.mkDefault)) (
    {
      # `terminal` is the one role that is not Linux-specific: nix-darwin/home.nix
      # imports modules/terminal.nix, which reads this role.
      terminal = { command = "ghostty"; };
    }
    # The rest are Linux desktop apps whose nixpkgs defaults have no darwin build.
    # Nothing on macOS consumes them, and declaring them would put packages that
    # cannot be built for that platform in the registry.
    // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
      fileManager = { command = "thunar"; };
      calculator = {
        command = "gnome-calculator";
        class = "org.gnome.Calculator";
        package = pkgs.gnome-calculator;
      };
      imageViewer = {
        command = "swayimg";
        package = pkgs.swayimg;
      };
      archiver = { command = "xarchiver"; };
      pdfViewer = { command = "okular"; };
    }
  );
}
