{
  description = "Flake for Darwin";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      # Use nix-darwin that tracks nixpkgs unstable (Apple Silicon)
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim-config = {
      url = "github:barleytea/nixvim-config";
      # nixpkgs を follows しない（nixvim-config 側で unstable を独自管理）
    };
    arion = {
      url = "github:hercules-ci/arion";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    yazi-plugins = {
      url = "github:yazi-rs/plugins/230b9c6055a3144f6974fef297ad1a91b46a6aac";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nix-darwin,
    nixvim-config,
    arion,
    yazi-plugins,
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
    linuxSystem = "x86_64-linux";

    pkgs = nixpkgs.legacyPackages.${system};
    pkgsLinux = import nixpkgs {
      system = linuxSystem;
      config = {
        allowUnfree = true;
        permittedInsecurePackages = [
          "google-chrome-144.0.7559.97"
        ];
      };
    };

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
        pkgs = nixpkgsWithOverlays;
        extraSpecialArgs = { inherit inputs; };
        modules = [
          ./home-manager/default.nix
        ];
      };
    };

    darwinConfigurations = {
      all = mkDarwinConfig [ ./darwin/default.nix ];
      homebrew = mkDarwinConfig [ ./darwin/homebrew/default.nix ];
      system = mkDarwinConfig [ ./darwin/system/default.nix ];
      service = mkDarwinConfig [ ./darwin/service/default.nix ];
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
