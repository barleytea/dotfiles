# File Server backup configuration
{ config, pkgs, ... }:

{
  # rsyncを使った自動バックアップ設定
  systemd.services.fileserver-backup = {
    description = "File server backup to secondary storage";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    script = with pkgs; ''
      # バックアップ開始ログ
      echo "Starting file server backup..." | ${systemd}/bin/systemd-cat -t fileserver-backup -p info
      
      # メインストレージからセカンダリストレージへのミラーリング
      ${rsync}/bin/rsync -av --delete \
        --exclude="lost+found" \
        --exclude=".DS_Store" \
        --exclude="Thumbs.db" \
        /mnt/sda1/shares/ \
        /mnt/sdb1/backup/sda1-mirror/
      
      backup_status=$?
      
      if [ $backup_status -eq 0 ]; then
        echo "Backup completed successfully" | ${systemd}/bin/systemd-cat -t fileserver-backup -p info
      else
        echo "Backup failed with status $backup_status" | ${systemd}/bin/systemd-cat -t fileserver-backup -p err
      fi
      
      # バックアップ統計情報をログ出力
      backup_size=$(${coreutils}/bin/du -sh /mnt/sdb1/backup/sda1-mirror/ | ${coreutils}/bin/cut -f1)
      echo "Backup size: $backup_size" | ${systemd}/bin/systemd-cat -t fileserver-backup -p info
    '';
  };

  # 毎日深夜2時にバックアップ実行
  systemd.timers.fileserver-backup = {
    description = "Run file server backup daily at 2 AM";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "02:00";
      Persistent = true;
      RandomizedDelaySec = "30min";  # 負荷分散のため最大30分遅延
    };
  };

  # スナップショット風バックアップ（週次）
  systemd.services.fileserver-snapshot = {
    description = "Create weekly snapshot of file server data";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    script = with pkgs; ''
      # スナップショット日付
      snapshot_date=$(${coreutils}/bin/date +%Y%m%d)
      snapshot_dir="/mnt/sdb1/snapshots/$snapshot_date"
      
      echo "Creating snapshot: $snapshot_dir" | ${systemd}/bin/systemd-cat -t fileserver-snapshot -p info
      
      # スナップショットディレクトリ作成
      ${coreutils}/bin/mkdir -p "$snapshot_dir"
      
      # ハードリンクを使用した効率的なスナップショット作成
      ${rsync}/bin/rsync -av --link-dest=/mnt/sdb1/backup/sda1-mirror/ \
        /mnt/sda1/shares/ \
        "$snapshot_dir/"
      
      snapshot_status=$?
      
      if [ $snapshot_status -eq 0 ]; then
        echo "Snapshot created successfully: $snapshot_dir" | ${systemd}/bin/systemd-cat -t fileserver-snapshot -p info
      else
        echo "Snapshot creation failed with status $snapshot_status" | ${systemd}/bin/systemd-cat -t fileserver-snapshot -p err
      fi
      
      # 古いスナップショットの削除（4週間以上古いもの）
      ${findutils}/bin/find /mnt/sdb1/snapshots/ -maxdepth 1 -type d -mtime +28 -exec rm -rf {} \;
    '';
  };

  # 毎週日曜日の3時にスナップショット作成
  systemd.timers.fileserver-snapshot = {
    description = "Create weekly snapshot on Sunday at 3 AM";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Sun 03:00";
      Persistent = true;
    };
  };

  # バックアップ関連パッケージ
  environment.systemPackages = with pkgs; [
    rsync
    rclone  # 将来的にクラウドバックアップに使用可能
  ];

  # バックアップディレクトリの作成
  systemd.tmpfiles.rules = [
    "d /mnt/sdb1/backup 0755 root root -"
    "d /mnt/sdb1/backup/sda1-mirror 0755 root root -"
    "d /mnt/sdb1/snapshots 0755 root root -"
  ];
} 