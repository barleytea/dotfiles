
# AGENTS.md を OS 別にレンダリングする共有関数。
#
# gh 認証セクションは OS で内容が違うため、テンプレ内のマーカー区間を差し替える。
# マーカー: <!-- gh-auth-section:begin ... --> ... <!-- gh-auth-section:end -->
#
# Claude (CLAUDE.md) / Gemini (GEMINI.md) / Codex (AGENTS.md) / Copilot
# (instructions) はすべてこの関数が返す同一のレンダリング結果を参照する。
{pkgs}: let
  ghAuthBeginMarker = "<!-- gh-auth-section:begin (rendered by modules/home/claude/default.nix) -->";
  ghAuthEndMarker = "<!-- gh-auth-section:end -->";

  ghAuthSectionDarwin = ''
    ${ghAuthBeginMarker}
    - `home-manager apply` 時に `~/.config/github-cli/config.yml` が自動生成される
    - 認証は `GH_TOKEN` 環境変数で行う（macOS Keychain で管理）
    - `dangerouslyDisableSandbox: true` は不要

    ```bash
    # macOS Keychain にトークンを登録（一回限り）
    security add-generic-password -s "gh-token" -a "$USER" -w "ghp_xxxx"
    # 既存エントリを更新する場合
    security add-generic-password -U -s "gh-token" -a "$USER" -w "ghp_xxxx"

    # ~/.zshrc_local に追記（既存の .zshrc が source している）
    _gh_token=$(security find-generic-password -s "gh-token" -a "$USER" -w 2>/dev/null)
    if [[ -n "$_gh_token" ]]; then
      export GH_TOKEN="$_gh_token"
    fi
    unset _gh_token
    ```

    Claude Code はシェルの環境変数を継承するため、
    `GH_TOKEN` が設定されたシェルから起動すれば `gh` コマンドが正常に動作する。
    トークンは dotfiles（Nix 管理ファイル）には書かず、macOS Keychain で管理する。
    ${ghAuthEndMarker}'';

  ghAuthSectionLinux = ''
    ${ghAuthBeginMarker}
    - `home-manager apply` 時に `~/.config/github-cli/config.yml` が自動生成される
    - 認証は `GH_TOKEN` 環境変数で行う（NixOS: libsecret/Secret Service もしくは pass で管理）
    - `dangerouslyDisableSandbox: true` は不要

    ```bash
    # 例1: libsecret (GNOME Keyring / KWallet 等) にトークンを登録（一回限り）
    secret-tool store --label="gh-token" service gh-token user "$USER"
    # プロンプトに ghp_xxxx を貼り付け

    # ~/.zshrc_local に追記（既存の .zshrc が source している）
    _gh_token=$(secret-tool lookup service gh-token user "$USER" 2>/dev/null)
    if [[ -n "$_gh_token" ]]; then
      export GH_TOKEN="$_gh_token"
    fi
    unset _gh_token

    # 例2: pass (Password Store) を使う場合
    # pass insert gh-token
    # _gh_token=$(pass show gh-token 2>/dev/null)
    ```

    Claude Code はシェルの環境変数を継承するため、
    `GH_TOKEN` が設定されたシェルから起動すれば `gh` コマンドが正常に動作する。
    トークンは dotfiles（Nix 管理ファイル）には書かず、Secret Service / pass / GPG 等で管理する。
    ${ghAuthEndMarker}'';

  ghAuthSection =
    if pkgs.stdenv.isDarwin
    then ghAuthSectionDarwin
    else ghAuthSectionLinux;

  # テンプレート内のマーカー区間全体を OS 別セクションに置換する。
  # マーカー間の本文は AGENTS.md 内で Darwin 版を保持しているため、
  # `${ghAuthSectionDarwin}` をテンプレートのマッチ文字列として利用できる。
  renderTemplate = path: let
    tpl = builtins.readFile path;
  in
    builtins.replaceStrings
    [ghAuthSectionDarwin]
    [ghAuthSection]
    tpl;
in
  # 評価時にテンプレートを読むためのパスはこのファイル自身からの相対パス
  # （Nix store にコピーされる）を使う。ランタイムのシンボリックリンク先を
  # 生成するわけではなく、レンダリング済みの内容を持つ単一の store パスを返す。
  pkgs.writeText "claude-AGENTS.md" (renderTemplate ./AGENTS.md)
