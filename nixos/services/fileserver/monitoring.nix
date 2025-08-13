# File Server monitoring configuration
{ config, pkgs, ... }:

{
  # システム監視とログ設定
  services.journald = {
    extraConfig = ''
      # ログファイルサイズ制限
      SystemMaxUse=500M
      SystemMaxFileSize=50M
      
      # ログ保持期間
      MaxRetentionSec=1month
    '';
  };

  # ディスク使用量監視スクリプト
  systemd.services.disk-monitor = {
    description = "Disk usage monitoring for file server";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    script = with pkgs; ''
      # ディスク使用率をチェック
      usage=$(${coreutils}/bin/df /mnt/sda1 | ${gawk}/bin/awk 'NR==2 {print $5}' | ${gnused}/bin/sed 's/%//')
      
      if [ "$usage" -gt 90 ]; then
        echo "WARNING: Disk usage on /mnt/sda1 is $usage%" | ${systemd}/bin/systemd-cat -t disk-monitor -p warning
      elif [ "$usage" -gt 80 ]; then
        echo "INFO: Disk usage on /mnt/sda1 is $usage%" | ${systemd}/bin/systemd-cat -t disk-monitor -p info
      fi
      
      # セカンダリディスクもチェック
      usage2=$(${coreutils}/bin/df /mnt/sdb1 | ${gawk}/bin/awk 'NR==2 {print $5}' | ${gnused}/bin/sed 's/%//')
      
      if [ "$usage2" -gt 90 ]; then
        echo "WARNING: Disk usage on /mnt/sdb1 is $usage2%" | ${systemd}/bin/systemd-cat -t disk-monitor -p warning
      elif [ "$usage2" -gt 80 ]; then
        echo "INFO: Disk usage on /mnt/sdb1 is $usage2%" | ${systemd}/bin/systemd-cat -t disk-monitor -p info
      fi
    '';
  };

  # 定期的なディスク監視
  systemd.timers.disk-monitor = {
    description = "Run disk monitoring every hour";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "15min";
      OnUnitActiveSec = "1h";
      Persistent = true;
    };
  };

  # Tailscale接続監視
  systemd.services.tailscale-monitor = {
    description = "Tailscale connection monitoring";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    script = with pkgs; ''
      status=$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)
      
      if [ "$status" != "Running" ]; then
        echo "WARNING: Tailscale is not running (status: $status)" | ${systemd}/bin/systemd-cat -t tailscale-monitor -p warning
      else
        echo "INFO: Tailscale is running normally" | ${systemd}/bin/systemd-cat -t tailscale-monitor -p info
      fi
    '';
  };

  # 定期的なTailscale監視
  systemd.timers.tailscale-monitor = {
    description = "Monitor Tailscale connection every 30 minutes";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "30min";
      Persistent = true;
    };
  };

  # ファイルサーバアクセスログ監視用設定
  environment.systemPackages = with pkgs; [
    # ログ解析ツール
    logrotate
    rsyslog
  ];
} 