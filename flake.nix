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
      ghostty,
      ...
    }:
    {
      # replace 'nixos' with your hostname here.
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        specialArgs = {
          hostname = "nixos"; # change to your hostname
          username = "green"; # change to your username
        };

        modules = [
          ./configuration.nix

          (
            { hostname, username, ... }:
            {
              networking.hostName = hostname;
              users.users.${username} = {
                isNormalUser = true;
                extraGroups = [
                  "wheel"
                  "networkmanager"
                ];
              };
            }
          )
          home-manager.nixosModules.home-manager
          (
            {
              hostname,
              username,
              ghostty,
              ...
            }:
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit hostname username ghostty; };
                users.${username} = import ./home.nix;
                sharedModules = [
                  catppuccin.homeModules.catppuccin
                ];
                backupFileExtension = "backup";
              };
            }
          )
        ];
      };
    };
}
