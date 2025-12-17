# nix-darwin 24.11 (Intel Mac) 専用の設定
# macOS 13 + Tier 3 で動作しないパッケージを除外
{ lib, ... }: {
  homebrew = {
    # nixpkgs からインストール済み、または macOS 13 でビルド不可のパッケージを除外
    brews = lib.mkForce [
      # "aqua"                      # nixpkgs から利用可能
      # "daipeihust/tap/im-select"  # Xcode 15.2+ 必要
      # "mas"                       # Xcode 16.0 必要（macOS 13 では不可）
      # "mise"                      # nixpkgs からインストール済み
      "n"
      # "uv"                        # Rust ビルドに時間がかかる、nixpkgs から利用可能
      "harelba/q/q"
      # "koekeishiya/formulae/skhd" # Xcode 15.2+ 必要
      # "koekeishiya/formulae/yabai" # Xcode 15.2+ 必要
    ];

    # ARM64 専用のcaskを除外
    casks = lib.mkForce [
      "android-studio"
      "apparency"
      "appcleaner"
      "caffeine"
      "cursor"
      "devutils"
      "dbeaver-community"
      "fig"
      "finicky"
      "font-hack-nerd-font"
      "gfxcardstatus"
      "ghostty"
      "google-japanese-ime"
      "hammerspoon"
      "iterm2"
      # "lm-studio"  # ARM64 専用
      "miro"
      "nosql-workbench"
      "notion"
      "plain-clip"
      "raycast"
      "rstudio"
      "the-unarchiver"
      "xquartz"
    ];
  };
}
