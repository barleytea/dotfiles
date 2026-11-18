# AI中心の小説執筆環境
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.writing;
  hermesCli = pkgs.writeShellScript "writing-hermes-cli" ''
    exec ${pkgs.util-linux}/bin/runuser -u ${cfg.user} -- env \
      HOME=/home/${cfg.user} \
      HERMES_HOME=${cfg.hermesHomeDir} \
      XDG_RUNTIME_DIR=/run/user/$(${pkgs.coreutils}/bin/id -u ${cfg.user}) \
      PATH=/home/${cfg.user}/.local/bin:/home/${cfg.user}/.nix-profile/bin:/etc/profiles/per-user/${cfg.user}/bin:/run/current-system/sw/bin \
      ${cfg.hermesPackage}/bin/hermes "$@"
  '';
  backupScript = pkgs.writeShellScript "writing-backup" ''
    set -eu
    source_dir="${cfg.sourceDir}"
    backup_root="${cfg.backupDir}"

    # マウント解除時に空のマウントポイントへバックアップしない。
    if ! ${pkgs.util-linux}/bin/mountpoint -q /mnt/sda1 || \
       ! ${pkgs.util-linux}/bin/mountpoint -q /mnt/sdb1; then
      echo "writing backup: required storage is not mounted" >&2
      exit 1
    fi
    if [ ! -d "$source_dir" ] || [ -z "$(${pkgs.findutils}/bin/find "$source_dir" -mindepth 1 -print -quit)" ]; then
      echo "writing backup: source is missing or empty; refusing to continue" >&2
      exit 1
    fi
    if [ "$(${pkgs.coreutils}/bin/stat -c %d "$source_dir")" != "$(${pkgs.coreutils}/bin/stat -c %d /mnt/sda1)" ]; then
      echo "writing backup: source is not on the expected mounted filesystem" >&2
      exit 1
    fi

    ${cfg.hermesBackupPackage}/bin/hermes-writing-backup \
      --source-dir "$source_dir" \
      --worktree-dir "${cfg.worktreeDir}" \
      --hermes-home "${cfg.hermesHomeDir}" \
      --backup-dir "$backup_root" \
      --generations "${toString cfg.generations}" \
      --bare-repo-dir /var/lib/git/novel.git \
      --skip-mount-check
  '';
in
{
  options.services.writing = {
    enable = mkEnableOption "private AI-assisted writing environment";

    user = mkOption {
      type = types.str;
      default = "miyoshi_s";
      description = "専用執筆環境を利用するユーザー";
    };

    sourceDir = mkOption {
      type = types.str;
      default = "/mnt/sda1/private/writing/novel";
      description = "小説データ全体の保存元。SMB/NFS/Kubernetesへ公開しない";
    };

    worktreeDir = mkOption {
      type = types.str;
      default = "/mnt/sda1/private/writing/worktrees/hermes";
      description = "Hermes 専用の小説 Git worktree";
    };

    hermesHomeDir = mkOption {
      type = types.str;
      default = "/mnt/sda1/private/writing/hermes";
      description = "Hermes の永続状態保存先。認証情報はバックアップしない";
    };

    backupDir = mkOption {
      type = types.str;
      default = "/mnt/sdb1/backup/private/writing";
      description = "世代バックアップの保存先";
    };

    generations = mkOption {
      type = types.ints.positive;
      default = 14;
      description = "保持する日次バックアップ世代数";
    };

    hermesBackupPackage = mkOption {
      type = types.package;
      description = "外部 Hermes Flake が提供するバックアップ実装";
    };

    hermesPackage = mkOption {
      type = types.package;
      description = "バックアップ時に実行する Hermes CLI パッケージ";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      git
      jq
      openssh
      psmisc
      rsync
      sqlite
      util-linux
      zellij
    ];

    systemd.services.writing-directory-setup = {
      description = "Prepare private writing directories without touching contents";
      wantedBy = [ "multi-user.target" ];
      after = [ "local-fs.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        RemainAfterExit = true;
        RequiresMountsFor = [ "/mnt/sda1" "/mnt/sdb1" ];
      };
      script = ''
        ${pkgs.util-linux}/bin/mountpoint -q /mnt/sda1
        ${pkgs.util-linux}/bin/mountpoint -q /mnt/sdb1
        source_dir="${cfg.sourceDir}"
        worktree_dir="${cfg.worktreeDir}"
        hermes_home="${cfg.hermesHomeDir}"
        backup_root="${cfg.backupDir}"
        source_parent="$(${pkgs.coreutils}/bin/dirname "$source_dir")"
        backup_parent="$(${pkgs.coreutils}/bin/dirname "$backup_root")"
        worktree_parent="$(${pkgs.coreutils}/bin/dirname "$worktree_dir")"
        hermes_parent="$(${pkgs.coreutils}/bin/dirname "$hermes_home")"
        ${pkgs.coreutils}/bin/mkdir -p /mnt/sda1/private "$source_parent" "$source_dir" "$worktree_parent" "$worktree_dir" "$hermes_parent" "$hermes_home" "$backup_parent" "$backup_root"
        ${pkgs.coreutils}/bin/chown ${cfg.user}:users /mnt/sda1/private "$source_parent" "$source_dir" "$worktree_parent" "$worktree_dir" "$hermes_parent" "$hermes_home"
        ${pkgs.coreutils}/bin/chmod 0700 /mnt/sda1/private "$source_parent" "$source_dir" "$worktree_parent" "$worktree_dir" "$hermes_parent" "$hermes_home"
        ${pkgs.coreutils}/bin/chown root:root "$backup_parent" "$backup_root"
        ${pkgs.coreutils}/bin/chmod 0700 "$backup_parent" "$backup_root"
      '';
    };

    systemd.services.writing-backup = {
      description = "Daily private writing backup";
      after = [ "writing-directory-setup.service" ];
      wants = [ "writing-directory-setup.service" ];
      path = with pkgs; [ bash coreutils findutils git jq psmisc rsync sqlite util-linux ];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        RequiresMountsFor = [ "/mnt/sda1" "/mnt/sdb1" ];
        Environment = [ "HERMES_BIN=${hermesCli}" ];
        ExecStart = backupScript;
      };
    };

    systemd.timers.writing-backup = {
      description = "Run private writing backup daily";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*-*-* 03:15:00";
        Persistent = true;
        RandomizedDelaySec = "15m";
      };
    };
  };
}
