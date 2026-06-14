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
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pvetui = {
      url = "github:devnullvoid/pvetui";
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
      nix-darwin,
      zen-browser,
      ...
    }:
    let
      hostname = "nixos"; # change to your hostname
      username = "green"; # change to your username
    in
    {
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
              zen-browser
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

      darwinConfigurations = {
        # macOS (nix-darwin)
        nix-darwin = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = {
            inherit
              ghostty
              gazelle
              hostname
              username
              tsui
              pvetui
              ;
          };

          modules = [
            ./nix-darwin/configuration.nix
            home-manager.darwinModules.home-manager
            (
              {
                hostname,
                username,
                ghostty,
                gazelle,
                tsui,
                pvetui,
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
                      ;
                  };
                  users.${username} = import ./nix-darwin/home.nix;
                  sharedModules = [
                    catppuccin.homeModules.catppuccin
                    gazelle.homeModules.gazelle
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
