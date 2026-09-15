# 単一ノードk3sクラスタ
{ pkgs, ... }:

{
  services.k3s = {
    enable = true;
    role = "server";

    # 単一ノードでも組み込みetcdを使い、将来のサーバー追加に備える。
    clusterInit = true;
    disable = [
      "servicelb"
      "traefik"
    ];

    # local-path-provisionerの既定領域を専用ディスクへ置く。
    extraFlags = [
      "--default-local-storage-path=/mnt/sda1/k3s/storage"
      "--secrets-encryption"
    ];
  };

  # マウント済みストレージ上のデータディレクトリをサービス開始前に用意する。
  systemd.tmpfiles.rules = [
    "d /mnt/sda1/k3s 0700 root root -"
    "d /mnt/sda1/k3s/storage 0700 root root -"
    "d /mnt/sda1/k3s/jellyfin 0700 root root -"
    "d /mnt/sda1/k3s/jellyfin/config 0700 1000 1000 -"
    "d /mnt/sda1/k3s/jellyfin/cache 0700 1000 1000 -"
  ];

  # hostPath を未マウントの /mnt/sda1 上へ誤作成しないよう、k3s 起動前に確認する。
  systemd.services.k3s-storage-setup = {
    description = "Prepare k3s hostPath directories";
    before = [ "k3s.service" ];
    wantedBy = [ "k3s.service" ];
    requires = [ "mnt-sda1.mount" ];
    after = [ "mnt-sda1.mount" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "root";
      RequiresMountsFor = [ "/mnt/sda1" ];
    };
    script = with pkgs; ''
      ${util-linux}/bin/mountpoint -q /mnt/sda1
      ${coreutils}/bin/mkdir -p /mnt/sda1/k3s/storage /mnt/sda1/k3s/jellyfin/config /mnt/sda1/k3s/jellyfin/cache
      ${coreutils}/bin/chmod 0700 /mnt/sda1/k3s /mnt/sda1/k3s/storage /mnt/sda1/k3s/jellyfin
      ${coreutils}/bin/chown 1000:1000 /mnt/sda1/k3s/jellyfin/config /mnt/sda1/k3s/jellyfin/cache
      ${coreutils}/bin/chmod 0700 /mnt/sda1/k3s/jellyfin/config /mnt/sda1/k3s/jellyfin/cache
    '';
  };

  systemd.services.k3s.after = [ "k3s-storage-setup.service" ];
  systemd.services.k3s.requires = [ "k3s-storage-setup.service" ];

  # クラスタ管理用CLI。認証情報は各ユーザーの環境で別途管理する。
  environment.systemPackages = with pkgs; [
    age
    fluxcd
    kubectl
    kubernetes-helm
    sops
  ];
}
