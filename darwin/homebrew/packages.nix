# Homebrew のパッケージ一覧（単一の正本）
#
# nix-darwin の homebrew モジュールと Home Manager の trust.json 生成の
# 両方がこのファイルを参照する。追加・削除はここだけを編集すること。
#
# tap 名を含む（スラッシュ区切りの）エントリは非公式 tap 由来とみなし、
# Homebrew 7.0.6 以降で必要な信頼リストへ自動的に組み込まれる。
{
  taps = [
    "daipeihust/tap"
    "FelixKratz/formulae"
    "harelba/q"
    "nikitabobko/tap"
    "stablyai/orca"
  ];

  brews = [
    "daipeihust/tap/im-select"
    "FelixKratz/formulae/borders"
    "mas"
    "mise"
    "n"
    "uv"
    "harelba/q/q"
    "jira-cli"
  ];

  casks = [
    "alt-tab"
    "apparency"
    "appcleaner"
    "caffeine"
    "cmux"
    "cursor"
    "devutils"
    "dbeaver-community"
    "finicky"
    "font-hack-nerd-font"
    "gfxcardstatus"
    "ghostty"
    "google-japanese-ime"
    "hammerspoon"
    "lm-studio"
    "miro"
    "nosql-workbench"
    "notion"
    "stablyai/orca/orca"
    "plain-clip"
    "raycast"
    "tableplus"
    "the-unarchiver"
    "zed"
    "xquartz"
    "nikitabobko/tap/aerospace"
  ];
}
