# File Server configuration
{ config, pkgs, ... }:

{
  imports = [
    ./samba.nix
    ./nfs.nix
    ./monitoring.nix
    ./backup.nix
  ];

  # ファイルサーバ用ユーザーグループの作成
  users.groups = {
    fileserver = {
      gid = 2000;
    };
    media = {
      gid = 2001;
    };
    backup = {
      gid = 2002;
    };
  };

  # 既存ユーザーをファイルサーバグループに追加
  users.users.miyoshi_s = {
    extraGroups = [ "fileserver" "media" "backup" ];
  };

  # ファイルサーバ用パッケージ
  environment.systemPackages = with pkgs; [
    samba
    nfs-utils
    cifs-utils
  ];
}
