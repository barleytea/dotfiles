# Storage management configuration
{ config, pkgs, ... }:

{
  imports = [
    ./directories.nix
  ];

  # 既存のファイルシステム設定を保持
  fileSystems = {
    "/mnt/sda1" = {
      device = "/dev/disk/by-uuid/71323b1e-e85e-4658-b2f1-ce64474bb85b";
      fsType = "ext4";
      options = [ "defaults" "user_xattr" "acl" ];  # ACLとextended attributesを有効化
    };
    "/mnt/sdb1" = {
      device = "/dev/disk/by-uuid/d002ced3-af30-411f-8d52-eb71b53ea6cf";
      fsType = "ext4";
      options = [ "defaults" "user_xattr" "acl" ];
    };
  };

  # ストレージヘルスチェック
  systemd.services.storage-health-check = {
    description = "Storage health monitoring";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    script = with pkgs; ''
      # S.M.A.R.T.データチェック
      ${smartmontools}/bin/smartctl -H /dev/sda || echo "WARNING: sda health check failed" | ${systemd}/bin/systemd-cat -t storage-health -p warning
      ${smartmontools}/bin/smartctl -H /dev/sdb || echo "WARNING: sdb health check failed" | ${systemd}/bin/systemd-cat -t storage-health -p warning

      # ファイルシステムチェック（読み取り専用）
      ${e2fsprogs}/bin/fsck.ext4 -n /dev/sda1 || echo "WARNING: sda1 filesystem check failed" | ${systemd}/bin/systemd-cat -t storage-health -p warning
      ${e2fsprogs}/bin/fsck.ext4 -n /dev/sdb1 || echo "WARNING: sdb1 filesystem check failed" | ${systemd}/bin/systemd-cat -t storage-health -p warning

      echo "Storage health check completed" | ${systemd}/bin/systemd-cat -t storage-health -p info
    '';
  };

  # 週次ストレージヘルスチェック
  systemd.timers.storage-health-check = {
    description = "Weekly storage health check";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Sun 01:00";
      Persistent = true;
    };
  };

  # ストレージ関連パッケージ
  environment.systemPackages = with pkgs; [
    smartmontools  # S.M.A.R.T.監視
    e2fsprogs      # ext4ツール
    parted         # パーティション管理
    hdparm         # ディスク管理
  ];
}
