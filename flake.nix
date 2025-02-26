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
    system = builtins.currentSystem;
    pkgs = nixpkgs.legacyPackages.${system};
  in {

    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [
        # TODO: Add your development packages here
      ];
      shellHook = ''
        $SHELL
      '';
    };

    homeConfigurations = {
      home = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        extraSpecialArgs = {
          inherit inputs;
        };
        modules = [
          ./home-manager/default.nix
        ];
      };
    };

    darwinConfigurations =  {
      all = nix-darwin.lib.darwinSystem {
        system = system;
        modules = [
          ./darwin/default.nix
        ];
      };

      homebrew = nix-darwin.lib.darwinSystem {
        system = system;
        modules = [
          ./darwin/homebrew/default.nix
        ];
      };

      system = nix-darwin.lib.darwinSystem {
        system = system;
        modules = [
          ./darwin/system/default.nix
        ];
      };

      service = nix-darwin.lib.darwinSystem {
        system = system;
        modules = [
          ./darwin/service/default.nix
        ];
      };
    };
  };
}
