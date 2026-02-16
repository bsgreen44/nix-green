{
  description = "Main Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    ghostty.url = "github:ghostty-org/ghostty";
    catppuccin.url = "github:catppuccin/nix/release-25.11";
    gazelle.url = "github:Zeus-Deus/gazelle-tui";
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      catppuccin,
      ghostty,
      gazelle,
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
              ;
          };

          modules = [
            ./kde/configuration.nix
            home-manager.nixosModules.home-manager
            (
              {
                hostname,
                username,
                ghostty,
                gazelle,
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
                      ;
                  };
                  users.${username} = import ./kde/home.nix;
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

        # Hyprland Desktop
        hyprland = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit
              ghostty
              gazelle
              hostname
              username
              ;
          };

          modules = [
            ./hyprland/configuration.nix
            home-manager.nixosModules.home-manager
            (
              {
                hostname,
                username,
                ghostty,
                gazelle,
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
                      ;
                  };
                  users.${username} = import ./hyprland/home.nix;
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
