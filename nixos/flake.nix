{
  description = "Flake for NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hermes-writing = {
      url = "github:gyokuroo/hermes-writing-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
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
    ai-guardrails = {
      # レビュースキル等のガードレール（instruction ファイルは dotfiles 側で管理するため無効化）
      url = "github:barleytea/ai-guardrails";
    };
    hunk = {
      url = "github:modem-dev/hunk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agent-dangomushi = {
      # dotfiles と同じ ghq ルート配下（`../../agent-dangomushi`）にクローン済みのローカルリポジトリを
      # 相対パスで参照する（GitHub 上で private/未push でも動く。CI では
      # `.github/ci-stubs/agent-dangomushi` に override される）
      url = "git+file:../../agent-dangomushi";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    hermes-writing,
    nixvim-config,
    dotfiles-shared,
    ai-guardrails,
    hunk,
    agent-dangomushi,
  } @ inputs: let
    system = "x86_64-linux";

    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
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
