{
  config,
  lib,
  pkgs,
  ...
}: let
  dotfilesPath = "${config.home.homeDirectory}/git_repos/github.com/barleytea/dotfiles";
  claudeConfigPath = "${dotfilesPath}/modules/home/claude/config";

  # AGENTS.md の OS 別レンダリングは Claude / Gemini / Codex / Copilot で共有する。
  renderedAgents = import "${claudeConfigPath}/render-agents.nix" {inherit pkgs;};

  # Claude Code の auto mode + sandbox 方針を Codex CLI の語彙に合わせたもの。
  # - approval_policy = "on-request": モデルが必要と判断したときだけ確認を求める
  #   （Claude Code の auto mode に相当）
  # - sandbox_mode = "workspace-write": 書き込みはワークスペース配下に限定
  #   （danger-full-access は使わない）
  # - sandbox_workspace_write.network_access = true: Codex のサンドボックスは
  #   ドメイン単位の許可リストを持たないため、Claude Code の allowedDomains
  #   ほど細かくは絞れない。ネットワークが必要な作業（依存関係の取得等）を
  #   妨げないよう on にしている
  #
  # TOML は `[section]` 以降に現れる key をすべてそのセクションに属するものと
  # 解釈するため、root レベルのキー（scalars）と table（sections）を分けて
  # 管理し、「base scalars → 既存ファイルの root 残り → base tables → 既存
  # ファイルの table 残り」の順で結合する。table を root キーより先に置くと、
  # 後から追記する既存ファイルの root キーが誤って table 配下に取り込まれる。
  codexConfigScalars = pkgs.writeText "codex-config-scalars" ''
    approval_policy = "on-request"
    approvals_reviewer = "auto_review"
    sandbox_mode = "workspace-write"
  '';
  codexConfigTables = pkgs.writeText "codex-config-tables" ''
    [sandbox_workspace_write]
    network_access = true
  '';
in {
  home.activation.configureCodex = lib.hm.dag.entryAfter ["writeBoundary"] ''
    codex_dir="${config.home.homeDirectory}/.codex"
    codex_config="$codex_dir/config.toml"
    tmp_config="$(${pkgs.coreutils}/bin/mktemp)"

    ${pkgs.coreutils}/bin/cat '${codexConfigScalars}' > "$tmp_config"
    if [ -f "$codex_config" ]; then
      # 既存ファイルのうち root レベル（最初の [section] より前）から
      # 管理下のキーを除いたものを追記する
      ${pkgs.gawk}/bin/awk '
        /^\[/ { exit }
        /^[[:space:]]*(approval_policy|approvals_reviewer|sandbox_mode)[[:space:]]*=/ { next }
        { print }
      ' "$codex_config" >> "$tmp_config"
    fi

    ${pkgs.coreutils}/bin/cat '${codexConfigTables}' >> "$tmp_config"
    if [ -f "$codex_config" ]; then
      # 既存ファイルのうち最初の [section] 以降から、管理下のテーブルを除いたものを追記する
      ${pkgs.gawk}/bin/awk '
        BEGIN { started = 0; skip_section = 0 }
        /^\[/ {
          started = 1
          skip_section = ($0 ~ /^\[sandbox_workspace_write\]/)
        }
        !started { next }
        skip_section { next }
        { print }
      ' "$codex_config" >> "$tmp_config"
    fi

    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$codex_dir"
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 600 "$tmp_config" "$codex_config"
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/rm -f "$tmp_config"

    # AGENTS.md は Claude / Gemini と同じ内容（人格・行動原則）を共有する。
    # Codex はこのファイルをグローバル指示として ~/.codex/AGENTS.md から読む。
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -sf "${renderedAgents}" "${config.home.homeDirectory}/.codex/AGENTS.md"
  '';
}
