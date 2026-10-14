{
  description = "Main Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin.url = "github:catppuccin/nix";
    gazelle = {
      url = "github:Zeus-Deus/gazelle-tui";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    tsui = {
      url = "github:neuralink/tsui";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      catppuccin,
      gazelle,
      tsui,
      hyprland,
      nix-darwin,
      zen-browser,
      ...
    }:
    let
      hostname = "nixos"; # change to your hostname
      username = "green"; # change to your username
      gaming = false; # true installs Steam, Proton and game launchers (modules/gaming.nix)
      gpu = "none"; # written by install.sh on NixOS: nvidia, amd, intel or none

      # Module args every configuration gets. Not `hyprland`: only the NixOS
      # Hyprland desktop has the flake input, and linux/hyprland.nix sets it to
      # null through _module.args, which a specialArg would override.
      args = { inherit hostname username gaming gpu gazelle tsui; };
      linuxArgs = args // { inherit zen-browser; };

      hmModules = [
        catppuccin.homeModules.catppuccin
        gazelle.homeModules.gazelle
      ];
      # No zen-browser on macOS: it ships as a homebrew cask there, and the
      # module would define programs.zen-browser, which packages.nix must never
      # reference on that platform.
      linuxHmModules = hmModules ++ [ zen-browser.homeModules.beta ];

      # Home Manager as a NixOS / nix-darwin module.
      hmFor = home: extraSpecialArgs: sharedModules: {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          inherit extraSpecialArgs sharedModules;
          users.${username} = import home;
          backupFileExtension = "backup";
        };
      };

      nixos = desktop: specialArgs: nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        inherit specialArgs;
        modules = [
          ./configuration.nix
          ./${desktop}/configuration.nix
          home-manager.nixosModules.home-manager
          (hmFor ./${desktop}/home.nix specialArgs linuxHmModules)
        ];
      };
    in
    {
      # Standalone Home Manager for non-NixOS distros.
      #   .#green           - CLI tools + dotfiles only
      #   .#green-hyprland  - the above plus the Hyprland desktop, for distros
      #                       where the compositor is installed by the distro's
      #                       own package manager rather than built by Nix.
      homeConfigurations =
        let
          standalone = entry: home-manager.lib.homeManagerConfiguration {
            pkgs = nixpkgs.legacyPackages."x86_64-linux";
            extraSpecialArgs = linuxArgs;
            modules = [ entry ] ++ linuxHmModules;
          };
        in
        {
          ${username} = standalone ./linux/home.nix;
          "${username}-hyprland" = standalone ./linux/hyprland.nix;
        };

      nixosConfigurations = {
        kde = nixos "kde" linuxArgs; # KDE Plasma Desktop
        hyprland = nixos "hyprland" (linuxArgs // { inherit hyprland; }); # Hyprland Desktop
      };

      darwinConfigurations = {
        # macOS (nix-darwin)
        nix-darwin = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin"; # use "x86_64-darwin" for Intel CPU
          specialArgs = args;
          modules = [
            ./nix-darwin/configuration.nix
            home-manager.darwinModules.home-manager
            (hmFor ./nix-darwin/home.nix args hmModules)
          ];
        };
      };
    };
}
