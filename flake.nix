{
  description = "Main Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ghostty.url = "github:ghostty-org/ghostty";
    catppuccin.url = "github:catppuccin/nix";
    gazelle.url = "github:Zeus-Deus/gazelle-tui";
    tsui.url = "github:neuralink/tsui";
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pvetui = {
      url = "github:devnullvoid/pvetui";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    herdr = {
      url = "github:ogulcancelik/herdr";
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
      ghostty,
      gazelle,
      tsui,
      hyprland,
      pvetui,
      herdr,
      zen-browser,
      ...
    }:
    let
      hostname = "nixos"; # change to your hostname
      username = "green"; # change to your username
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
            extraSpecialArgs = {
              inherit
                username
                hostname
                ghostty
                gazelle
                tsui
                pvetui
                herdr
                zen-browser
                ;
            };
            modules = [
              entry
              catppuccin.homeModules.catppuccin
              gazelle.homeModules.gazelle
              zen-browser.homeModules.beta
            ];
          };
        in
        {
          ${username} = standalone ./linux/home.nix;
          "${username}-hyprland" = standalone ./linux/hyprland.nix;
        };

      nixosConfigurations = {
        # KDE Plasma Desktop
        kde = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit
              ghostty
              gazelle
              hostname
              username
              tsui
              pvetui
              herdr
              ;
          };

          modules = [
            ./configuration.nix
            ./kde/configuration.nix
            home-manager.nixosModules.home-manager
            (
              {
                hostname,
                username,
                ghostty,
                gazelle,
                tsui,
                pvetui,
                herdr,
                zen-browser,
                ...
              }:
              {
                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  extraSpecialArgs = {
                    inherit
                      hostname
                      username
                      ghostty
                      gazelle
                      tsui
                      pvetui
                      herdr
                      zen-browser
                      ;
                  };
                  users.${username} = import ./kde/home.nix;
                  sharedModules = [
                    catppuccin.homeModules.catppuccin
                    gazelle.homeModules.gazelle
                    zen-browser.homeModules.beta
                  ];
                  backupFileExtension = "backup";
                };
              }
            )
          ];
        };

        # Hyprland Desktop
        hyprland = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit
              ghostty
              gazelle
              hostname
              username
              tsui
              hyprland
              pvetui
              herdr
              zen-browser
              ;
          };

          modules = [
            ./configuration.nix
            ./hyprland/configuration.nix
            home-manager.nixosModules.home-manager
            (
              {
                hostname,
                username,
                ghostty,
                gazelle,
                tsui,
                hyprland,
                pvetui,
                herdr,
                zen-browser,
                ...
              }:
              {
                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  extraSpecialArgs = {
                    inherit
                      hostname
                      username
                      ghostty
                      gazelle
                      tsui
                      hyprland
                      pvetui
                      herdr
                      zen-browser
                      ;
                  };
                  users.${username} = import ./hyprland/home.nix;
                  sharedModules = [
                    catppuccin.homeModules.catppuccin
                    gazelle.homeModules.gazelle
                    zen-browser.homeModules.beta
                  ];
                  backupFileExtension = "backup";
                };
              }
            )
          ];
        };
      };
    };
}
