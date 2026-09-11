{ config, pkgs, lib, ... }:

let
  dotfilesPath = "${config.home.homeDirectory}/git_repos/github.com/barleytea/dotfiles";
  geminiConfigPath = "${dotfilesPath}/modules/home/gemini/config";

  # AGENTS.md の OS 別レンダリングは Claude / Gemini / Codex / Copilot で共有する。
  # （以前は未レンダリングの生 AGENTS.md を直接リンクしており、Linux でも
  #   Darwin 向け gh 認証手順が表示されるバグがあった）
  #
  # import はビルド評価時にファイルを読むため、実行時のホームディレクトリ文字列
  # ではなく、このファイル自身からの相対 Nix パス（flake ソースツリー内、
  # eval 時に Nix store へコピーされる）で参照する必要がある。
  renderedAgents = import ../claude/config/render-agents.nix {inherit pkgs;};
in
{
  home.activation.creategeminiSymlinks = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "${config.home.homeDirectory}/.gemini"
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -sf "${renderedAgents}" "${config.home.homeDirectory}/.gemini/GEMINI.md"
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -sf "${geminiConfigPath}/settings.json" "${config.home.homeDirectory}/.gemini/settings.json"
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -sf "${geminiConfigPath}/commands" "${config.home.homeDirectory}/.gemini/commands"
  '';
}
