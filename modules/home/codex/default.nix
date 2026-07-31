{
  config,
  lib,
  pkgs,
  ...
}: let
  codexConfigBase = pkgs.writeText "codex-config-base" ''
    approval_policy = "on-request"
    approvals_reviewer = "auto_review"
  '';
in {
  home.activation.configureCodex = lib.hm.dag.entryAfter ["writeBoundary"] ''
    codex_dir="${config.home.homeDirectory}/.codex"
    codex_config="$codex_dir/config.toml"
    tmp_config="$(${pkgs.coreutils}/bin/mktemp)"

    ${pkgs.coreutils}/bin/cat '${codexConfigBase}' > "$tmp_config"
    if [ -f "$codex_config" ]; then
      ${pkgs.gawk}/bin/awk '
        BEGIN { in_top_level = 1 }
        /^\[/ { in_top_level = 0 }
        in_top_level && /^[[:space:]]*(approval_policy|approvals_reviewer)[[:space:]]*=/ { next }
        { print }
      ' "$codex_config" >> "$tmp_config"
    fi

    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$codex_dir"
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 600 "$tmp_config" "$codex_config"
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/rm -f "$tmp_config"
  '';
}
