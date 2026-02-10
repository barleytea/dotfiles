{
  description = "My Nixvim configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixvim,
    ...
  }: let
    systems = ["aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux"];
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    # (1) standalone パッケージ: nix run / nix build で利用可能
    packages = forAllSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      default = nixvim.legacyPackages.${system}.makeNixvimWithModule {
        inherit pkgs;
        module = import ./config;
      };
    });

    # (2) home-manager モジュール: dotfiles 等からインポート
    homeManagerModules.default = {pkgs, ...}: {
      home.packages = [
        self.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
      home.sessionVariables.EDITOR = "nvim";
      home.shellAliases = {
        vi = "nvim";
        vim = "nvim";
        vimdiff = "nvim -d";
      };
      programs.neovim = {
        viAlias = true;
        vimAlias = true;
        vimdiffAlias = true;
      };
    };
  };
}
