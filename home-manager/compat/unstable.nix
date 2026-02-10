# nixpkgs unstable専用のパッケージ・設定
# 24.11には存在しない、またはビルドに失敗するパッケージをここに集約
{ pkgs, ... }: {
  home.packages = with pkgs; [
    # unstable での nerd-fonts パッケージ名
    nerd-fonts.hack
    # unstable のみで利用可能なパッケージ
    xan
  ];
}
