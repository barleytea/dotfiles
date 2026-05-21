{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  username = if builtins.getEnv "USER" == "runner" then builtins.getEnv "USER" else "miyoshi_s";
  home = "/Users/${username}";
  npmrcBase = pkgs.writeText "npmrc-base" ''
    prefix=${config.home.homeDirectory}/.npm-global
    min-release-age=7
  '';
  shared = inputs.dotfiles-shared;
in {

  # nixpkgs config is supplied by the caller (darwin flake sets allowUnfree)

  imports = [
    inputs.nixvim-config.homeManagerModules.default
    # 共通 HM モジュール（modules/home/ から）
    "${shared}/home/alacritty"
    "${shared}/home/atuin"
    "${shared}/home/cz-git"
    "${shared}/home/editorconfig"
    "${shared}/home/helix"
    "${shared}/home/lazygit"
    "${shared}/home/sheldon"
    "${shared}/home/starship"
    "${shared}/home/tmux"
    "${shared}/home/yazi"
    "${shared}/home/zed"
    # OS 固有・差分ありモジュール
    ./aerospace
    ./cmux
    ./borders
    ./claude
    ./gemini
    ./ghostty
    ./git
    ./mise
    ./shell
    ./zellij
  ];

  home = {
    username = username;
    homeDirectory = home;
    stateVersion = "24.05";

    packages = import ./packages/packages.nix { inherit pkgs; };

    file.".local/bin/zellij-worktree-switcher" = {
      text = builtins.readFile ./scripts/zellij-worktree-switcher.sh;
      executable = true;
    };

    file.".local/bin/zellij-worktree-remove" = {
      text = builtins.readFile ./scripts/zellij-worktree-remove.sh;
      executable = true;
    };

    file.".local/bin/zellij-session-switcher" = {
      text = builtins.readFile ./scripts/zellij-session-switcher.sh;
      executable = true;
    };

    file.".local/bin/send-to-pane" = {
      text = builtins.readFile ./scripts/send-to-pane.sh;
      executable = true;
    };

    file.".local/bin/send-to-tab" = {
      text = builtins.readFile ./scripts/send-to-tab.sh;
      executable = true;
    };

    file.".local/bin/claude-add-dir" = {
      text = builtins.readFile ./scripts/claude-add-dir.sh;
      executable = true;
    };

  };

  # .npmrc を実ファイルとして配置し、safe-chain や npm が追記できるようにする
  home.activation.mergeNpmrc = lib.hm.dag.entryAfter ["writeBoundary"] ''
    tmp_npmrc="$(${pkgs.coreutils}/bin/mktemp)"
    if [ -f "$HOME/.npmrc_local" ]; then
      ${pkgs.coreutils}/bin/cat '${npmrcBase}' "$HOME/.npmrc_local" > "$tmp_npmrc"
    else
      ${pkgs.coreutils}/bin/cp '${npmrcBase}' "$tmp_npmrc"
    fi

    $DRY_RUN_CMD rm -f "$HOME/.npmrc"
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 600 "$tmp_npmrc" "$HOME/.npmrc"
    $DRY_RUN_CMD rm -f "$tmp_npmrc"
  '';

  # Enable security tools (Kali Linux) on Linux systems
}
