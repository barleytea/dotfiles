{
  description = "Flake for Darwin";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nix-darwin,
    neovim-nightly-overlay,
  } @ inputs: let
    # system = "aarch64-darwin"; # "aarch64-darwin" | # "x86_64-darwin" | "x86_64-linux";
    system = builtins.currentSystem;
  in {

    homeConfigurations = {
      home = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        extraSpecialArgs = {
          inherit inputs;
        };
        modules = [
          ./home/default.nix
        ];
      };
    };

    darwinConfigurations.darwin = nix-darwin.lib.darwinSystem {
      system = system;
      modules = [ 
        ./darwin/default.nix
      ];
    };
  };
}
