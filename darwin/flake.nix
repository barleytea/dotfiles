{
  description = "Flake for Darwin (macOS)";

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
    nixvim-config = {
      # Avoid path input escaping flake root during pure evaluation.
      url = "git+file:..?dir=nixvim";
      flake = true;
    };
    dotfiles-shared = {
      # 共通 HM モジュール群（modules/ 以下を直接参照）
      url = "git+file:..?dir=modules";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nix-darwin,
    nixvim-config,
    dotfiles-shared,
  } @ inputs: let
    darwinSystems = [
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    hostSystem =
      if builtins ? currentSystem
      then builtins.currentSystem
      else null;
    system =
      if hostSystem != null && builtins.elem hostSystem darwinSystems
      then hostSystem
      else "aarch64-darwin"; # Default to Apple Silicon Mac

    pkgs = nixpkgs.legacyPackages.${system};

    # Override to skip tests
    nixpkgsWithOverlays = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
        permittedInsecurePackages = [
          "google-chrome-144.0.7559.97"
        ];
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

    # darwin設定用のヘルパー関数
    mkDarwinConfig = modules: nix-darwin.lib.darwinSystem {
      inherit system;
      modules = modules;
    };
  in {
    homeConfigurations = {
      home = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgsWithOverlays;
        extraSpecialArgs = { inherit inputs; };
        modules = [
          ./home-manager/default.nix
        ];
      };
    };

    darwinConfigurations = {
      all = mkDarwinConfig [ ./default.nix ];
      homebrew = mkDarwinConfig [ ./homebrew/default.nix ];
      system = mkDarwinConfig [ ./system/default.nix ];
    };
  };
}
