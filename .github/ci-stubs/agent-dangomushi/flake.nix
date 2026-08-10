{
  description = "CI 用 agent-dangomushi スタブ（private リポジトリの代わりに eval を通すためのモック）";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: {
    nixosModules.default = {
      lib,
      config,
      ...
    }: {
      options.services.agent-dangomushi = {
        enable = lib.mkEnableOption "agent-dangomushi (CI stub)";
        environmentFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "CI stub: 実体は持たないダミーオプション";
        };
      };

      # CI では eval できれば十分なため、実際の systemd サービス等は定義しない
      config = {};
    };
  };
}
