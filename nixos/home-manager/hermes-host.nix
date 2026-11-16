{ ... }:

{
  services.hermes-writing = {
    enable = true;
    hermesHome = "/mnt/sda1/private/writing/hermes";
    workingDirectory = "/mnt/sda1/private/writing/worktrees/hermes";
    repository = "/mnt/sda1/private/writing/novel";
    branch = "agent/hermes-writing";
    storageMount = "/mnt/sda1";
    environmentFiles = [ "/mnt/sda1/private/writing/hermes.env" ];

    github = {
      home = "/mnt/sda1/private/writing/hermes/github";
      user = "gyokuroo";
      authorEmail = "357243118+gyokuroo@users.noreply.github.com";
    };

    provider = "openai-codex";
    model = "gpt-6-sol";
  };
}
