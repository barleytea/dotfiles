# NFS (Network File System) configuration
{ lib, config, pkgs, ... }:

{
  services.nfs.server = {
    enable = true;

    # NFSv4前提のエクスポート設定（Tailscale CGNATレンジ）
    # 注意: showmount は使えなくなる場合があります（v4のみ運用）
    exports = ''
      # NFSv4 ルート（擬似ルート）
      /mnt/sda1/shares        100.64.0.0/10(ro,fsid=0,no_subtree_check,crossmnt)
      
      # サブエクスポート（擬似ルート配下）
      /mnt/sda1/shares/docker 100.64.0.0/10(rw,sync,no_subtree_check)
      /mnt/sda1/shares/dev    100.64.0.0/10(rw,sync,no_subtree_check)
      /mnt/sda1/shares/media  100.64.0.0/10(ro,sync,no_subtree_check)
    '';
  };

  # nfs.conf に相当する設定（NFSv4のみ・UDP無効・スレッド数指定）
  services.nfs.settings = {
    nfsd = {
      udp = false;
      vers2 = false;
      vers3 = false;
      vers4 = true;
      "vers4.0" = true;
      "vers4.1" = true;
      "vers4.2" = true;
      threads = 8;
      # 必要なら特定IPにバインド（Tailscale IPに置換）
      # host = "100.x.y.z";
    };
  };

  # rpcbind/statd はデフォルトに委ねる（v4のみでも起動可。依存解決を優先）
  # services.rpcbind.enable = lib.mkForce false;
  # systemd.services."rpc-statd".enable = lib.mkForce false;
  # systemd.sockets."rpcbind".enable = lib.mkForce false;
  # systemd.services."rpcbind".enable = lib.mkForce false;

  # NFSv4-onlyのため必要ポートは2049のみ（Tailscale経由のみ許可）
  networking.firewall = {
    interfaces.tailscale0 = {
      allowedTCPPorts = [ 2049 ];
      allowedUDPPorts = [ 2049 ];
    };
  };

  # 起動安定化のためnfsdカーネルモジュールを事前ロード
  boot.kernelModules = [ "nfsd" ];
} 