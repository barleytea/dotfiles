{
  inputs,
  lib,
  pkgs,
  ...
}: let
  reviewSkills = {
    architecture = "Review boundaries, coupling, ownership, and configuration flow for concrete design risks.";
    code-quality = "Review changed code for correctness, error handling, data-flow, and maintainability defects.";
    dependencies = "Review dependency changes for unnecessary scope, security, licensing, and lockfile risks.";
    documentation = "Review documentation for omissions or contradictions that could cause user failure or misuse.";
    layering = "Review whether responsibilities and dependencies remain in their correct architectural layers.";
    performance = "Review changed code for measurable performance regressions, unbounded work, and repeated I/O.";
    security = "Review changed code for exploitable vulnerabilities and affected trust boundaries.";
    testing = "Review whether important changed behavior and concrete failure modes have meaningful test coverage.";
  };

  makeAgentSkill = name: description: let
    skillFile = pkgs.writeText "review-${name}-SKILL.md" (
      builtins.replaceStrings
      ["name: ${name}\n"]
      ["name: review-${name}\ndescription: ${builtins.toJSON description}\n"]
      (builtins.readFile (inputs.ai-guardrails + "/generated/claude-code/skills/${name}/SKILL.md"))
    );
  in
    pkgs.runCommand "review-${name}" {} ''
      ${pkgs.coreutils}/bin/mkdir -p "$out"
      ${pkgs.coreutils}/bin/cp "${skillFile}" "$out/SKILL.md"
    '';

  reviewSkillFiles = lib.mapAttrs' (name: description: {
    name = "review-${name}";
    value.source = makeAgentSkill name description;
  }) reviewSkills;

  installSkillRoot = root:
    lib.mapAttrs' (name: value: {
      name = "${root}/${name}";
      inherit value;
    }) reviewSkillFiles;
in {
  # Codex と Gemini は Agent Skills 標準のユーザースコープを共有する。
  # Codex の旧バージョン向けに ~/.codex/skills も維持する。
  home.file = lib.mergeAttrsList (map installSkillRoot [
    ".agents/skills"
    ".codex/skills"
  ]);
}
