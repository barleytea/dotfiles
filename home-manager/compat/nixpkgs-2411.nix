# nixpkgs 24.11専用のパッケージ・設定
# 24.11 と unstable でパッケージ名や利用可否が異なるものをここに集約
{ pkgs, ... }: {
  home.packages = [
    # 24.11 での nerd-fonts パッケージ名（unstable とは異なる）
    (pkgs.nerdfonts.override { fonts = [ "Hack" ]; })
  ];
}
