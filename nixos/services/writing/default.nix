# AI中心の小説執筆環境
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.writing;
  backupScript = pkgs.writeShellScript "writing-backup" ''
    set -eu
    source_dir="${cfg.sourceDir}"
    backup_root="${cfg.backupDir}"
    generation="$(date +%Y-%m-%d_%H-%M-%S)"
    destination="$backup_root/$generation"

    # マウント解除時に空のマウントポイントへバックアップしない。
    if ! ${pkgs.util-linux}/bin/mountpoint -q /mnt/sda1 || \
       ! ${pkgs.util-linux}/bin/mountpoint -q /mnt/sdb1; then
      echo "writing backup: required storage is not mounted" >&2
      exit 1
    fi
    if [ ! -d "$source_dir" ] || [ -z "$(${pkgs.coreutils}/bin/find "$source_dir" -mindepth 1 -print -quit)" ]; then
      echo "writing backup: source is missing or empty; refusing to continue" >&2
      exit 1
    fi
    if [ "$(${pkgs.coreutils}/bin/stat -c %d "$source_dir")" != "$(${pkgs.coreutils}/bin/stat -c %d /mnt/sda1)" ]; then
      echo "writing backup: source is not on the expected mounted filesystem" >&2
      exit 1
    fi

    ${pkgs.coreutils}/bin/mkdir -p "$backup_root"
    ${pkgs.coreutils}/bin/mkdir "$destination"
    ${pkgs.rsync}/bin/rsync -aH --numeric-ids -- "$source_dir/" "$destination/novel/"

    # 既存の bare repository は再初期化せず、履歴の保全用に別領域へ複製する。
    if [ -d /var/lib/git/novel.git ]; then
      ${pkgs.rsync}/bin/rsync -aH --numeric-ids -- /var/lib/git/novel.git/ "$destination/novel.git/"
    fi
    ${pkgs.coreutils}/bin/chmod -R go-rwx "$destination"
    ${pkgs.coreutils}/bin/find "$backup_root" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' \
      | ${pkgs.coreutils}/bin/sort -nr | ${pkgs.coreutils}/bin/tail -n +${toString (cfg.generations + 1)} \
      | ${pkgs.gawk}/bin/awk '{ sub(/^[^ ]* /, ""); print }' \
      | while IFS= read -r old; do [ -n "$old" ] && ${pkgs.coreutils}/bin/rm -rf -- "$old"; done
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
      description = "小説本文の正本。SMB/NFS/Kubernetesへ公開しない";
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
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      git
      openssh
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
        backup_root="${cfg.backupDir}"
        source_parent="$(${pkgs.coreutils}/bin/dirname "$source_dir")"
        backup_parent="$(${pkgs.coreutils}/bin/dirname "$backup_root")"
        ${pkgs.coreutils}/bin/mkdir -p /mnt/sda1/private "$source_parent" "$source_dir" "$backup_parent" "$backup_root"
        ${pkgs.coreutils}/bin/chown ${cfg.user}:users /mnt/sda1/private "$source_parent" "$source_dir"
        ${pkgs.coreutils}/bin/chmod 0700 /mnt/sda1/private "$source_parent" "$source_dir"
        ${pkgs.coreutils}/bin/chown root:root "$backup_parent" "$backup_root"
        ${pkgs.coreutils}/bin/chmod 0700 "$backup_parent" "$backup_root"
      '';
    };

    systemd.services.writing-backup = {
      description = "Daily private writing backup";
      after = [ "writing-directory-setup.service" ];
      wants = [ "writing-directory-setup.service" ];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        RequiresMountsFor = [ "/mnt/sda1" "/mnt/sdb1" ];
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
