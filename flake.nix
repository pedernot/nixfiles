{
  description = "NixOS flake";

  inputs = {
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    ...
  } @ inputs: {
    packages.x86_64-linux = home-manager.packages.x86_64-linux;

    nixosConfigurations = {
      lapping = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        system = "x86_64-linux";
        modules = [
          {
            nixpkgs.overlays = [inputs.neovim-nightly-overlay.overlays.default];
          }
          ./lapping/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {inherit inputs;};
            home-manager.sharedModules = [
              {
                nixpkgs.overlays = [inputs.neovim-nightly-overlay.overlays.default];
              }
            ];
            home-manager.users.peder = import ./lapping/home.nix;
          }
        ];
      };
      heisenberg = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        system = "x86_64-linux";
        modules = [
          {
            nixpkgs.overlays = [inputs.neovim-nightly-overlay.overlays.default];
          }
          ./heisenberg/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {inherit inputs;};
            home-manager.sharedModules = [
              {
                nixpkgs.overlays = [inputs.neovim-nightly-overlay.overlays.default];
              }
            ];
            home-manager.users.peder = import ./heisenberg/home.nix;
          }
        ];
      };
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          {
            nixpkgs.overlays = [inputs.neovim-nightly-overlay.overlays.default];
          }
          ./nixos/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {inherit inputs;};
            home-manager.sharedModules = [
              {
                nixpkgs.overlays = [inputs.neovim-nightly-overlay.overlays.default];
              }
            ];
            home-manager.users.peder = import ./nixos/home.nix;
          }
        ];
      };
    };
  };
}
