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
    # Intel Mac (x86_64-darwin) 用の 24.11 リリース
    nixpkgs-2411 = {
      url = "github:nixos/nixpkgs?ref=nixos-24.11";
    };
    home-manager-2411 = {
      url = "github:nix-community/home-manager?ref=release-24.11";
      inputs.nixpkgs.follows = "nixpkgs-2411";
    };
    nix-darwin-2411 = {
      url = "github:LnL7/nix-darwin?ref=nix-darwin-24.11";
      inputs.nixpkgs.follows = "nixpkgs-2411";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    arion = {
      url = "github:hercules-ci/arion";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nix-darwin,
    nixpkgs-2411,
    home-manager-2411,
    nix-darwin-2411,
    nixvim,
    arion,
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
    
    # Intel Mac (x86_64-darwin) の場合は 24.11 を使用、それ以外は unstable を使用
    isIntelMac = system == "x86_64-darwin";
    selectedNixpkgs = if isIntelMac then nixpkgs-2411 else nixpkgs;
    selectedHomeManager = if isIntelMac then home-manager-2411 else home-manager;
    selectedNixDarwin = if isIntelMac then nix-darwin-2411 else nix-darwin;
    
    pkgs = selectedNixpkgs.legacyPackages.${system};
    unstablePkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
      };
    };
    pkgsLinux = import nixpkgs {
      system = linuxSystem;
      config = {
        allowUnfree = true;
      };
    };

    # Override to skip tests
    nixpkgsWithOverlays = import selectedNixpkgs {
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
      ] ++ (if isIntelMac then [
        # Intel Mac (24.11) では nix パッケージのテストが失敗するためスキップ
        (final: prev: {
          nix = prev.nix.overrideAttrs (oldAttrs: {
            doCheck = false;
            doInstallCheck = false;
          });
        })
        # gwq のビルドで Go 1.24 が必要なため、unstable から提供
        (final: prev: {
          go_1_24 = unstablePkgs.go_1_24 or unstablePkgs.go;
        })
      ] else []);
    };

    # darwin設定用のヘルパー関数
    mkDarwinConfig = modules: selectedNixDarwin.lib.darwinSystem {
      inherit system;
      modules = modules ++ (if isIntelMac
        then [ ./darwin/compat/nixpkgs-2411.nix ]
        else [ ./darwin/compat/unstable.nix ]);
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
      home = selectedHomeManager.lib.homeManagerConfiguration {
        pkgs = nixpkgsWithOverlays;
        extraSpecialArgs = { inherit inputs; };
        modules = [
          ./home-manager/default.nix
        ] ++ (if isIntelMac
          then [ ./home-manager/compat/nixpkgs-2411.nix ]
          else [ ./home-manager/compat/unstable.nix ]);
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
