{ pkgs, ... }:

let
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
    hermesHome = "/mnt/sda1/private/writing/hermes";
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
