# Samba (SMB/CIFS) configuration
{ config, pkgs, ... }:

{
  services.samba = {
    enable = true;
    # nmbdは無効化（NetBIOS不要、wsddで代替）
    nmbd.enable = false;
    smbd.enable = true;

    # Global設定（新しいsettings形式）
    settings = {
      global = {
        # ワークグループ名
        workgroup = "WORKGROUP";

        # サーバー説明
        "server string" = "NixOS File Server";

        # ログレベル
        "log level" = "1";
        "log file" = "/var/log/samba/log.%m";
        "max log size" = "1000";

        # セキュリティ設定（securityTypeはdeprecated）
        security = "user";
        "encrypt passwords" = "yes";

        # ネットワーク設定はファイアウォールで制御（明示バインドは行わない）

        # パフォーマンス設定
        "socket options" = "TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=65536 SO_SNDBUF=65536";

        # 文字エンコーディング
        "unix charset" = "UTF-8";
        "dos charset" = "CP932";
      };

      # 共有フォルダ設定
      public = {
        path = "/mnt/sda1/shares/public";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0664";
        "directory mask" = "0775";
        "valid users" = "miyoshi_s";
        comment = "Public file sharing";
      };

      media = {
        path = "/mnt/sda1/shares/media";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0664";
        "directory mask" = "0775";
        "force user" = "miyoshi_s";
        "force group" = "media";
        "vfs objects" = "catia fruit streams_xattr";
        "fruit:aapl" = "yes";
        "valid users" = "miyoshi_s";
        comment = "Media files (read-write)";
      };

      backup = {
        path = "/mnt/sda1/shares/backup";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0664";
        "directory mask" = "0775";
        "valid users" = "miyoshi_s";
        comment = "Backup storage (Time Machine compatible)";

        # Time Machine対応設定
        "fruit:aapl" = "yes";
        "fruit:time machine" = "yes";
        "vfs objects" = "catia fruit streams_xattr";
      };

      docker = {
        path = "/mnt/sda1/shares/docker";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0664";
        "directory mask" = "0775";
        "valid users" = "miyoshi_s";
        comment = "Docker volumes";
      };
    };
  };

  # Sambaサービスが起動するまでwinsを無効化
  services.samba-wsdd.enable = true;

  # smbdの起動順序調整（ネットワークとディレクトリ準備後）
  systemd.services."samba-smbd" = {
    after = [ "network-online.target" "fileserver-directory-setup.service" ];
    wants = [ "network-online.target" "fileserver-directory-setup.service" ];
  };

  # ファイアウォール設定（Tailscale経由のみ）
  networking.firewall = {
    interfaces.tailscale0 = {
      allowedTCPPorts = [ 139 445 ];
      allowedUDPPorts = [ 137 138 ];
    };
    # ローカルLANに露出しないようにデフォルトでは他IFは開かない
  };
}
