{ config, pkgs, lib, ... }:

let
  dotfilesPath = "${config.home.homeDirectory}/git_repos/github.com/barleytea/dotfiles";
  claudeConfigPath = "${dotfilesPath}/modules/home/claude/config";
  ghConfigBase = pkgs.writeText "gh-config" ''
    version: 1
    git_protocol: https
  '';

  # gh 認証セクションは OS で内容が違うため、テンプレ内のマーカー区間を差し替える。
  # マーカー: <!-- gh-auth-section:begin ... --> ... <!-- gh-auth-section:end -->
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

  ghAuthSection = if pkgs.stdenv.isDarwin then ghAuthSectionDarwin else ghAuthSectionLinux;

  # テンプレート内のマーカー区間全体を OS 別セクションに置換する。
  # マーカー間の本文は AGENTS.md / CLAUDE.md 双方で同一の Darwin 版を保持しているため、
  # `${ghAuthSectionDarwin}` をテンプレートのマッチ文字列として利用できる。
  renderTemplate = path: let
    tpl = builtins.readFile path;
  in builtins.replaceStrings
    [ ghAuthSectionDarwin ]
    [ ghAuthSection ]
    tpl;

  # 評価時にテンプレートを読むためのパスは、モジュール自身の相対パス
  # （Nix store にコピーされる）を使う。ランタイムのシンボリックリンク先は
  # `claudeConfigPath`（ユーザのワーキングコピー）のまま据え置く。
  renderedAgents = pkgs.writeText "claude-AGENTS.md" (renderTemplate (./config/AGENTS.md));
in
{
  home.activation.setupGhConfigDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p \
      "${config.home.homeDirectory}/.config/github-cli"
    if [ ! -f "${config.home.homeDirectory}/.config/github-cli/config.yml" ]; then
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 644 \
        '${ghConfigBase}' "${config.home.homeDirectory}/.config/github-cli/config.yml"
    fi
  '';

  home.activation.createClaudeSymlinks = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "${config.home.homeDirectory}/.config/claude"
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "${config.home.homeDirectory}/.claude/commands"
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "${config.home.homeDirectory}/.claude/skills"
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -sf "${renderedAgents}" "${config.home.homeDirectory}/.claude/CLAUDE.md"
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -sf "${claudeConfigPath}/settings.json" "${config.home.homeDirectory}/.claude/settings.json"
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -sf "${claudeConfigPath}/statusline.sh" "${config.home.homeDirectory}/.claude/statusline.sh"

    # Link individual files from commands directory
    if [ -d "${claudeConfigPath}/commands" ]; then
      for file in "${claudeConfigPath}/commands"/*; do
        if [ -f "$file" ]; then
          filename=$(${pkgs.coreutils}/bin/basename "$file")
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -sfn "$file" "${config.home.homeDirectory}/.claude/commands/$filename"
        fi
      done
    fi

    # Link skill directories from skills directory
    if [ -d "${claudeConfigPath}/skills" ]; then
      for skillDir in "${claudeConfigPath}/skills"/*; do
        if [ -d "$skillDir" ]; then
          skillName=$(${pkgs.coreutils}/bin/basename "$skillDir")
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -sfn "$skillDir" "${config.home.homeDirectory}/.claude/skills/$skillName"
        fi
      done
    fi

    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "${config.home.homeDirectory}/.claude/hooks"

    # Link hook scripts from hooks directory
    if [ -d "${claudeConfigPath}/hooks" ]; then
      for file in "${claudeConfigPath}/hooks"/*; do
        if [ -f "$file" ]; then
          filename=$(${pkgs.coreutils}/bin/basename "$file")
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -sfn "$file" "${config.home.homeDirectory}/.claude/hooks/$filename"
        fi
      done
    fi
  '';
}
