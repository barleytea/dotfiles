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
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nix-darwin,
    nixvim,
  } @ inputs: let
    system = "aarch64-darwin"; # Default to Apple Silicon Mac
    pkgs = nixpkgs.legacyPackages.${system};

    # Override to skip tests
    nixpkgsWithOverlays = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
      };
      overlays = [
        (final: prev: {
          haskellPackages = prev.haskellPackages.override {
            overrides = hfinal: hprev: {
              system-fileio = hprev.system-fileio.overrideAttrs (oldAttrs: {
                doCheck = false;
              });
              persistent-sqlite = hprev.persistent-sqlite.overrideAttrs (oldAttrs: {
                doCheck = false;
              });
            };
          };
        })
      ];
    };
  in {

    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [
        # Testing
        (bats.withLibraries (p: [ p.bats-support p.bats-assert p.bats-file ]))
      ];
    };

    homeConfigurations = {
      home = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgsWithOverlays;  # オーバーライドしたpkgsを使用
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

    # NixOS configurations (新規追加)
    nixosConfigurations = {
      desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./nixos/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.miyoshi_s = import ./home-manager;
              extraSpecialArgs = { inherit inputs; };
            };
          }
        ];
      };
    };
  };
}
