{
  description = "NixOS flake";

  inputs = {
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nvf = {
      url = "github:NotAShelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    kolide-launcher = {
      url = "github:/kolide/nix-agent/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    system = "x86_64-linux";
  in {
    packages.${system} = home-manager.packages.${system};

    nixosConfigurations = {
      lapping = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        system = "x86_64-linux";
        modules = [
          ./lapping/configuration.nix
          inputs.kolide-launcher.nixosModules.kolide-launcher
          inputs.stylix.nixosModules.stylix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useUserPackages = true;
              sharedModules = [inputs.nvf.homeManagerModules.default];
              extraSpecialArgs = {inherit inputs;};
              users.peder = import ./lapping/home.nix;
            };
          }
        ];
      };
      heisenberg = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        system = "x86_64-linux";
        modules = [
          ./heisenberg/configuration.nix
          inputs.stylix.nixosModules.stylix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useUserPackages = true;
              sharedModules = [inputs.nvf.homeManagerModules.default];
              extraSpecialArgs = {inherit inputs;};
              users.peder = import ./heisenberg/home.nix;
            };
          }
        ];
      };
      nixos = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        system = "x86_64-linux";
        modules = [
          ./nixos/configuration.nix
          inputs.stylix.nixosModules.stylix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useUserPackages = true;
              sharedModules = [inputs.nvf.homeManagerModules.default];
              extraSpecialArgs = {inherit inputs;};
              users.peder = import ./nixos/home.nix;
            };
          }
        ];
      };
    };
  };
}
