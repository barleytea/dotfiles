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
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nix-darwin,
  } @ inputs: let
    system = "aarch64-darwin"; # "aarch64-darwin" | # "x86_64-darwin" | "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    packages.${system}.barleytea-packages = pkgs.buildEnv {
      name = "barleytea-packages-list";
      paths = with pkgs; [];
    };

    apps.${system}.update = {
      type = "app";
      program = toString (pkgs.writeShellScript "update-script" ''
        set -e
        echo "Updating flake..."
        nix flake update
        echo "Updating profile..."
        nix profile upgrade barleytea-packages
        echo "Updating home-manager..."
        nix run nixpkgs#home-manager -- switch --flake .#barleyteaHomeConfig
        echo "Updating nix-darwin..."
        nix run nix-darwin -- switch --flake .#barleytea-darwin
        echo "Update complete!"
      '');
    };

    homeConfigurations = {
      barleyteaHomeConfig = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgs;
        extraSpecialArgs = {
          inherit inputs;
        };
        modules = [
          ./.config/nix/home-manager/default.nix
        ];
      };
    };
    darwinConfigurations.barleytea-darwin = nix-darwin.lib.darwinSystem {
      system = system;
      modules = [ ./.config/nix/nix-darwin/default.nix ];
    };
  };
}
