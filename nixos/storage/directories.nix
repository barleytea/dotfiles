# Directory management for file server
{ config, pkgs, ... }:

{
  # systemd-tmpfilesを使用したディレクトリ自動作成
  systemd.tmpfiles.rules = [
    # メインストレージディレクトリ
    "d /mnt/sda1/shares 0755 root root -"
    "d /mnt/sda1/shares/public 0775 miyoshi_s fileserver -"
    "d /mnt/sda1/shares/media 0755 miyoshi_s media -"
    "d /mnt/sda1/shares/backup 0775 miyoshi_s backup -"
    "d /mnt/sda1/shares/docker 0775 miyoshi_s fileserver -"
    "d /mnt/sda1/shares/dev 0775 miyoshi_s fileserver -"
    
    # セカンダリストレージディレクトリ
    "d /mnt/sdb1/backup 0755 root root -"
    "d /mnt/sdb1/backup/sda1-mirror 0755 root root -"
    "d /mnt/sdb1/shares 0755 root root -"
    "d /mnt/sdb1/shares/archive 0775 miyoshi_s fileserver -"
    "d /mnt/sdb1/snapshots 0755 root root -"
  ];

  # ディレクトリセットアップスクリプト
  systemd.services.fileserver-directory-setup = {
    description = "File server directory setup and permissions";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "root";
    };
    script = with pkgs; ''
      # ディレクトリが存在することを確認
      for dir in \
        "/mnt/sda1/shares" \
        "/mnt/sda1/shares/public" \
        "/mnt/sda1/shares/media" \
        "/mnt/sda1/shares/backup" \
        "/mnt/sda1/shares/docker" \
        "/mnt/sda1/shares/dev" \
        "/mnt/sdb1/backup" \
        "/mnt/sdb1/shares" \
        "/mnt/sdb1/shares/archive"; do
        
        if [ ! -d "$dir" ]; then
          echo "Creating directory: $dir" | ${systemd}/bin/systemd-cat -t directory-setup -p info
          ${coreutils}/bin/mkdir -p "$dir"
        fi
      done
      
      # 権限設定
      ${coreutils}/bin/chown -R miyoshi_s:fileserver /mnt/sda1/shares/public
      ${coreutils}/bin/chown -R miyoshi_s:media /mnt/sda1/shares/media
      ${coreutils}/bin/chown -R miyoshi_s:backup /mnt/sda1/shares/backup
      ${coreutils}/bin/chown -R miyoshi_s:fileserver /mnt/sda1/shares/docker
      ${coreutils}/bin/chown -R miyoshi_s:fileserver /mnt/sda1/shares/dev
      ${coreutils}/bin/chown -R miyoshi_s:fileserver /mnt/sdb1/shares/archive
      
      # パーミッション設定
      ${coreutils}/bin/chmod 0775 /mnt/sda1/shares/public
      ${coreutils}/bin/chmod 0755 /mnt/sda1/shares/media
      ${coreutils}/bin/chmod 0775 /mnt/sda1/shares/backup
      ${coreutils}/bin/chmod 0775 /mnt/sda1/shares/docker
      ${coreutils}/bin/chmod 0775 /mnt/sda1/shares/dev
      ${coreutils}/bin/chmod 0775 /mnt/sdb1/shares/archive
      
      # デフォルトACLの設定（新しいファイル/ディレクトリに自動適用）
      if command -v setfacl >/dev/null 2>&1; then
        ${acl}/bin/setfacl -d -m g:fileserver:rwx /mnt/sda1/shares/public
        ${acl}/bin/setfacl -d -m g:fileserver:rwx /mnt/sda1/shares/docker
        ${acl}/bin/setfacl -d -m g:fileserver:rwx /mnt/sda1/shares/dev
        ${acl}/bin/setfacl -d -m g:backup:rwx /mnt/sda1/shares/backup
        ${acl}/bin/setfacl -d -m g:media:rx /mnt/sda1/shares/media
      fi
      
      echo "Directory setup completed" | ${systemd}/bin/systemd-cat -t directory-setup -p info
    '';
  };

  # README ファイルの作成
  systemd.services.fileserver-readme-setup = {
    description = "Create README files for file server shares";
    wantedBy = [ "multi-user.target" ];
    after = [ "fileserver-directory-setup.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "root";
    };
    script = ''
      # README.md ファイルの作成
      cat > /mnt/sda1/shares/README.md << 'EOF'
# NixOS File Server

このディレクトリは NixOS ファイルサーバの共有フォルダです。

## 共有フォルダ構成

- **public**: 一般的なファイル共有
- **media**: メディアファイル（動画・音楽等）- 読み取り専用
- **backup**: バックアップデータ（Time Machine対応）
- **docker**: Docker volume用
- **dev**: 開発用ファイル

## アクセス方法

### SMB/CIFS
- Windows: \\nixos\共有名
- macOS: smb://nixos/共有名
- Linux: //nixos/共有名

### NFS (Linuxのみ)
- nixos:/mnt/sda1/shares/共有名

## 注意事項

- VPN (Tailscale) 経由でのみアクセス可能
- 適切な権限設定を維持してください
- 重要なデータは定期的にバックアップされます

作成日: $(date)
EOF

      cat > /mnt/sda1/shares/public/README.txt << 'EOF'
Public File Share
================

このフォルダは一般的なファイル共有用です。
読み書き権限があります。

アクセス方法:
- SMB: \\nixos\public または smb://nixos/public
- NFS: nixos:/mnt/sda1/shares/public (Linux)

EOF

      cat > /mnt/sda1/shares/media/README.txt << 'EOF'
Media Files (Read Only)
======================

このフォルダはメディアファイル用です。
読み取り専用に設定されています。

対応ファイル: 動画、音楽、画像など

アクセス方法:
- SMB: \\nixos\media または smb://nixos/media
- NFS: nixos:/mnt/sda1/shares/media (Linux, 読み取り専用)

EOF

      echo "README files created" | systemd-cat -t readme-setup -p info
    '';
  };

  # ACL関連パッケージ
  environment.systemPackages = with pkgs; [
    acl  # ACL管理ツール
  ];
} 