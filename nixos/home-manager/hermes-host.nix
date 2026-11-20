{ config, inputs, lib, pkgs, ... }:

let
  hermesHome = "/mnt/sda1/private/writing/hermes";
  shared = "${inputs.dotfiles-shared}";
  skillRegistry = builtins.fromJSON (builtins.readFile "${shared}/home/agent-skills/registry.json");
  hermesSkills = builtins.filter (skill: skill.hermes) skillRegistry.skills;
  hermesSkillNames =
    let names = map (skill: skill.name) hermesSkills;
    in assert lib.all (name: builtins.match "[A-Za-z0-9][A-Za-z0-9._-]*" name != null) names; names;
  claudeSubscriptionProviderSrc = pkgs.fetchFromGitHub {
    owner = "NousResearch";
    repo = "hermes-official-plugins";
    rev = "20048e6e2c1c48d6023e73ae6951595f58352b20";
    hash = "sha256-YZUMf3zMrKed8VKXpWk4F9+mXBFX4QWQiR69E49+TAA=";
  };
  claudeSubscriptionProvider = pkgs.runCommand "hermes-claude-subscription-directsdk" {} ''
    mkdir -p "$out"
    cp -r ${claudeSubscriptionProviderSrc}/claude-subscription-directsdk/. "$out/"
  '';
in

{
  home.activation = lib.mkIf (hermesSkills != []) {
    syncHermesAgentSkills = lib.hm.dag.entryAfter ["createClaudeSymlinks"] ''
      set -eu
      hermes_home="${hermesHome}"
      skills_dir="$hermes_home/skills"
      writing_skills_dir="$skills_dir/writing"

      if ! ${pkgs.util-linux}/bin/mountpoint -q /mnt/sda1; then
        echo "Hermes skill sync: /mnt/sda1 is not mounted" >&2
        exit 1
      fi
      if [ -L "$hermes_home" ] || [ ! -d "$hermes_home" ]; then
        echo "Hermes skill sync: Hermes home is missing or is a symlink" >&2
        exit 1
      fi
      mounted_device="$(${pkgs.coreutils}/bin/stat -c %d /mnt/sda1)"
      hermes_device="$(${pkgs.coreutils}/bin/stat -c %d "$hermes_home")"
      if [ "$mounted_device" != "$hermes_device" ]; then
        echo "Hermes skill sync: Hermes home is not on the mounted writing filesystem" >&2
        exit 1
      fi
      if [ -L "$skills_dir" ] || [ -L "$writing_skills_dir" ]; then
        echo "Hermes skill sync: refusing to follow a symlink in the skill destination" >&2
        exit 1
      fi

      $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -d -m 0700 "$writing_skills_dir"
      for skill_name in ${lib.escapeShellArgs hermesSkillNames}; do
        source_dir="${config.home.homeDirectory}/.agents/skills/$skill_name"
        target_dir="$writing_skills_dir/$skill_name"

        if [ ! -f "$source_dir/SKILL.md" ]; then
          echo "Hermes skill sync: required skill $skill_name is not available in ~/.agents/skills" >&2
          exit 1
        fi
        if [ -L "$target_dir" ] || { [ -e "$target_dir" ] && [ ! -d "$target_dir" ]; }; then
          echo "Hermes skill sync: refusing to replace unsafe destination $target_dir" >&2
          exit 1
        fi

        $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -d -m 0700 "$target_dir"
        $DRY_RUN_CMD ${pkgs.rsync}/bin/rsync -r --delete "$source_dir/" "$target_dir/"
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/chmod -R u+rwX,go-rwx "$target_dir"
      done
    '';
  };

  services.hermes-agent = {
    extraPackages = [ pkgs.claude-code ];
    extraPlugins = [ claudeSubscriptionProvider ];
    settings = {
      fallback_model = [];
      fallback_providers = [];
    };
  };

  services.hermes-writing = {
    enable = true;
    hermesHome = hermesHome;
    workingDirectory = "/mnt/sda1/private/writing/worktrees/hermes";
    repository = "/mnt/sda1/private/writing/novel/product";
    branch = "agent/hermes-writing";
    storageMount = "/mnt/sda1";

    github = {
      home = "/mnt/sda1/private/writing/hermes/github";
      user = "gyokuroo";
      authorEmail = "357243118+gyokuroo@users.noreply.github.com";
    };

    provider = "claude-subscription-directsdk-experimental";
    model = "sonnet";
  };
}
