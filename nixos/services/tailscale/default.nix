# Tailscale VPN configuration
{ config, pkgs, ... }:

{
  # Tailscaleサービス有効化
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";  # Exit Node機能とSubnet Router機能
  };

  # ファイアウォール設定
  networking.firewall = {
    enable = true;
    # Tailscaleインターフェースを信頼済みとして設定
    trustedInterfaces = [ "tailscale0" ];
    
    # VPN経由のみ許可、外部アクセス無効
    allowedTCPPorts = [ 
      # SSH, SMB, NFSはTailscale経由のみアクセス可能
    ];
    allowedUDPPorts = [ 
      41641  # Tailscale
    ];
  };

  # systemd-resolvedとの統合
  services.resolved.enable = true;
  
  # 自動接続サービス
  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale";
    after = [ "network-online.target" "tailscaled.service" ];
    wants = [ "network-online.target" "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    
    script = with pkgs; ''
      # tailscaledが起動するまで待機
      sleep 2

      # 既に認証済みかチェック
      status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
      if [ "$status" = "Running" ]; then
        echo "Tailscale is already running"
        exit 0
      fi

      # 初回起動時は手動認証が必要
      if [ "$status" = "NeedsLogin" ]; then
        echo "Tailscale needs authentication. Please run: sudo tailscale up --accept-routes --advertise-exit-node --ssh"
        exit 0
      fi

      # 認証済みの場合は自動接続（SSH有効化でホストキー公開）
      ${tailscale}/bin/tailscale up --accept-routes --advertise-exit-node --ssh
    '';
  };

  # Tailscale関連パッケージをシステムに追加
  environment.systemPackages = with pkgs; [
    tailscale
  ];
} 