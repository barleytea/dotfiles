{
  lib,
  pkgs,
  ...
}: let
  # 第三者の Agent Skill「imozuru」（芋づる式の調べもの）。
  # 上流の最新を取りに行かず commit を固定し、レビューで見つけた穴を塞ぐ hardening.patch を当ててから配る。
  # パッチの中身:
  # - fetch.py / watch.py: http(s) 以外の URL と、手元・内部のアドレス（転送先を含む）を断る
  # - fetch.py: 保存名を文字・数字・「.」「_」「-」に絞る、yt-dlp に「--」を渡す、外部コマンドにタイムアウトを付ける
  # - report.py: 抜き書きの file を sources/ の中に限る
  # - watch.py: コメントや UTF-16 で DOCTYPE の検査をすり抜けられないようにする
  # - SKILL.md: 落とした原文を指示ではなくデータとして扱う一文を足す
  # 上流を更新するときは rev と hash を上げ、差分をレビューしてからパッチを作り直す。
  imozuru = pkgs.stdenvNoCC.mkDerivation {
    pname = "imozuru-skill";
    version = "0-unstable-2026-10-16";

    src = pkgs.fetchFromGitHub {
      owner = "MaryCache";
      repo = "imozuru";
      rev = "0d656febbc3f5e0a20cb03d3e011b703e69fe034";
      hash = "sha256-vYacjKbILMcBQ+zUC3SbUq02HjnQedl80SzvBazhwFw=";
    };

    patches = [./hardening.patch];

    dontBuild = true;

    # パッチが上流の変更とずれていないかを、上流のテストとパッチで足したテストで確かめる
    doCheck = true;
    nativeCheckInputs = [pkgs.python3];
    checkPhase = ''
      runHook preCheck
      python3 -m unittest discover -s tests
      runHook postCheck
    '';

    installPhase = ''
      runHook preInstall
      cp -r skills/imozuru "$out"
      runHook postInstall
    '';
  };

  # ~/.agents/skills は Codex / Gemini CLI / GitHub Copilot が共通で読む Agent Skills 標準の置き場。
  # ~/.codex/skills は Codex の旧バージョン向け（modules/home/ai-guardrails と同じ扱い）。
  skillRoots = [
    ".agents/skills"
    ".claude/skills"
    ".codex/skills"
    ".cursor/skills"
  ];
in {
  home.file = lib.genAttrs (map (root: "${root}/imozuru") skillRoots) (_: {source = imozuru;});
}
