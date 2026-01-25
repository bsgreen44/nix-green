{
  description = "Main Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    ghostty.url = "github:ghostty-org/ghostty";
    catppuccin.url = "github:catppuccin/nix/release-25.11";
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      catppuccin,
      ...
    }:
    {
      # replace 'nixos' with your hostname here.
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              # replace 'green' with your username
              users.green = import ./home.nix;
              sharedModules = [
                catppuccin.homeModules.catppuccin
              ];
              backupFileExtension = "backup";
            };
          }
          (
            { pkgs, ... }:
            {
              environment.systemPackages = [
                pkgs.ghostty
              ];
            }
          )
        ];
      };
    };
}
