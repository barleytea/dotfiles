# Git SSH Server configuration
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.gitserver;
in
{
  options.services.gitserver = {
    enable = mkEnableOption "Git SSH server with bare repositories";

    user = mkOption {
      type = types.str;
      default = "git";
      description = "User account for Git repositories";
    };

    group = mkOption {
      type = types.str;
      default = "git";
      description = "Group for Git repositories";
    };

    repoDir = mkOption {
      type = types.path;
      default = "/var/lib/git";
      description = "Directory where Git bare repositories are stored";
    };

    authorizedKeys = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of SSH public keys authorized to access Git repositories";
    };

    repositories = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of repository names to initialize as bare repositories";
      example = [ "myproject.git" "dotfiles.git" ];
    };
  };

  config = mkIf cfg.enable {
    # Create git user and group
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.repoDir;
      createHome = true;
      shell = "${pkgs.git}/bin/git-shell";
      openssh.authorizedKeys.keys = cfg.authorizedKeys;
      description = "Git repository user";
    };

    users.groups.${cfg.group} = {};

    # Enable SSH daemon
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        PubkeyAuthentication = true;
      };
    };

    # Open SSH port in firewall
    networking.firewall.allowedTCPPorts = [ 22 ];

    # Install git package system-wide
    environment.systemPackages = with pkgs; [
      git
      openssh
    ];

    # Initialize bare repositories using systemd
    systemd.services.git-init-repos = {
      description = "Initialize Git bare repositories";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        Group = cfg.group;
        RemainAfterExit = true;
      };
      script = ''
        ${concatMapStringsSep "\n" (repo: ''
          if [ ! -d "${cfg.repoDir}/${repo}" ]; then
            echo "Initializing repository: ${repo}"
            ${pkgs.git}/bin/git init --bare "${cfg.repoDir}/${repo}"
            echo "Repository ${repo} initialized successfully"
          else
            echo "Repository ${repo} already exists, skipping"
          fi
        '') cfg.repositories}
      '';
    };

    # Set proper permissions for repository directory
    systemd.tmpfiles.rules = [
      "d ${cfg.repoDir} 0755 ${cfg.user} ${cfg.group} -"
    ];
  };
}
