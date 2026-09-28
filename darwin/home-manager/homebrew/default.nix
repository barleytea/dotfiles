{ lib, pkgs, ... }:
let
  packages = import ../../homebrew/packages.nix;

  # 非公式 tap 由来のエントリは "tap/owner/name" 形式でスラッシュを含む。
  # 公式の homebrew/core・homebrew/cask 由来は既定で信頼されるため対象外。
  isThirdParty = name: lib.hasInfix "/" name;

  # brew は tap 名を小文字に正規化して保持する（例: FelixKratz → felixkratz）。
  normalize = name: lib.toLower name;

  trustedFrom = names: map normalize (builtins.filter isThirdParty names);

  trustFile = pkgs.writeText "homebrew-trust.json" (builtins.toJSON {
    trustedformulae = trustedFrom packages.brews;
    trustedcasks = trustedFrom packages.casks;
  });
in
{
  # Homebrew 7.0.6 以降、公式以外の tap は明示的に信頼しないと読み込まれない。
  #
  # nix-darwin は Brewfile に trusted: true を付与するため、nix-darwin 経由の
  # 適用では信頼設定が自動で解決される。ただしその際 sudo が XDG_CONFIG_HOME を
  # 落とすため、書き込み先は ~/.homebrew/trust.json になる。
  # 対してユーザーが直接 brew を実行する場合は XDG_CONFIG_HOME が効くため
  # $XDG_CONFIG_HOME/homebrew/trust.json が参照され、そちらは更新されない。
  #
  # 手動実行時に信頼が欠けるのを防ぐため、こちらを宣言的に配置する。
  # 一覧は darwin/homebrew/packages.nix を唯一の正本として導出するので、
  # パッケージを追加・削除しても同期ずれは起きない。
  xdg.configFile."homebrew/trust.json" = {
    source = trustFile;
    force = true;
  };
}
