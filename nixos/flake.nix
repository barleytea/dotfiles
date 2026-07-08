{
  description = "Flake for NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
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
    hunk = {
      url = "github:modem-dev/hunk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agent-dangomushi = {
      # dotfiles と同一マシン上にクローン済みのローカルリポジトリを直接参照する
      # （GitHub 上で private/未push でも動く）
      url = "git+file:///home/miyoshi_s/git_repos/github.com/barleytea/agent-dangomushi";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nixvim-config,
    dotfiles-shared,
    hunk,
    agent-dangomushi,
  } @ inputs: let
    system = "x86_64-linux";

    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
        permittedInsecurePackages = [
          "google-chrome-144.0.7559.97"
        ];
      };
    };
  in {
    nixosConfigurations = {
      desktop = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
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
