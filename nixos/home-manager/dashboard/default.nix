# デスクトップ背景ダッシュボード（eww + 定期フェッチ）
#
# Wayland layer-shell の BOTTOM レイヤーに非対話のウィジェットを常駐させ、
# 天気・時刻・システム状態・生活情報を壁紙の上に表示する。
# データ取得は systemd user timer に任せ、eww はローカルの JSON を読むだけにすることで
# ネットワーク断でも表示が空にならないようにしている。
{
  config,
  pkgs,
  lib,
  ...
}: let
  # 表示対象の地域。地域を変えるときはここだけ書き換える。
  # Hyprland の gammastep も座標を持つが（nixos/desktop/hyprland/config.nix）、
  # system モジュールと HM モジュールを結合させる価値がないため独立させている
  location = {
    label = "川崎";
    latitude = "35.5308";
    longitude = "139.7029";
    jmaAreaCode = "140000"; # 神奈川県（気象警報・注意報の取得単位）
    jmaWarningArea = "1413000"; # 川崎市（警報の絞り込み。空文字なら県全域を集約）
  };

  # 空き容量を表示するマウントポイント。存在しないものは df が黙って落とす
  diskTargets = [
    "/"
    "/mnt/sda1"
    "/mnt/sdb1"
  ];

  dataFile = "${config.xdg.cacheHome}/dashboard/data.json";

  # errexit は付けない。1 つのデータソースの失敗で全体を殺さないため
  bashOptions = [
    "nounset"
    "pipefail"
  ];

  dashboardFetch = pkgs.writeShellApplication {
    name = "dashboard-fetch";
    runtimeInputs = with pkgs; [coreutils curl jq python3];
    # jq プログラムを add ラッパー経由で渡しているため、shellcheck が
    # 「jq への引数」と認識できず単一引用符内の $var に SC2016 を出す
    excludeShellChecks = ["SC2016"];
    inherit bashOptions;
    runtimeEnv = {
      DASHBOARD_DATA_FILE = dataFile;
      DASHBOARD_LAT = location.latitude;
      DASHBOARD_LON = location.longitude;
      DASHBOARD_JMA_AREA = location.jmaAreaCode;
      DASHBOARD_JMA_WARNING_AREA = location.jmaWarningArea;
      DASHBOARD_PLACE_LABEL = location.label;
    };
    text = builtins.readFile ./fetch.sh;
  };

  dashboardLive = pkgs.writeShellApplication {
    name = "dashboard-live";
    runtimeInputs = with pkgs; [coreutils gawk jq];
    inherit bashOptions;
    runtimeEnv.DASHBOARD_DISKS = lib.concatStringsSep " " diskTargets;
    text = builtins.readFile ./live.sh;
  };

  dashboardGpu = pkgs.writeShellApplication {
    name = "dashboard-gpu";
    runtimeInputs = with pkgs; [coreutils];
    inherit bashOptions;
    text = builtins.readFile ./gpu.sh;
  };

  dashboardData = pkgs.writeShellApplication {
    name = "dashboard-data";
    runtimeInputs = with pkgs; [jq];
    inherit bashOptions;
    runtimeEnv.DASHBOARD_DATA_FILE = dataFile;
    text = builtins.readFile ./data.sh;
  };

  # eww daemon は起動してもウィンドウを開かないため別途 open が必要。
  # eww open は単体だとデーモンを勝手に fork するので --no-daemonize で封じる
  dashboardOpen = pkgs.writeShellApplication {
    name = "dashboard-open";
    runtimeInputs = with pkgs; [coreutils eww];
    # eww ping 自体が内部で 5 回リトライする（1 回あたり約 1 秒）ため、
    # 20 回で最悪 20 秒強。DefaultTimeoutStartSec には十分収まる
    text = ''
      attempt=0
      while [ "$attempt" -lt 20 ]; do
          if eww ping >/dev/null 2>&1; then
              break
          fi
          attempt=$((attempt + 1))
          sleep 0.2
      done
      eww --no-daemonize open dashboard
    '';
  };
in {
  xdg.configFile."eww/eww.yuck".source = ./eww.yuck;
  xdg.configFile."eww/eww.scss".source = ./eww.scss;

  systemd.user.services.dashboard-fetch = {
    Unit.Description = "生活情報ダッシュボードのデータ取得";

    Service = {
      Type = "oneshot";
      ExecStart = "${dashboardFetch}/bin/dashboard-fetch";
      # curl 6 本 ×（--max-time 10 + リトライ）の最悪値に余裕を持たせる
      TimeoutStartSec = "3min";
      SyslogIdentifier = "dashboard-fetch";
    };
  };

  systemd.user.timers.dashboard-fetch = {
    Unit.Description = "生活情報ダッシュボードのデータ取得（10 分間隔）";

    Timer = {
      # user unit なので OnBootSec ではなくユーザーマネージャ起動基準の OnStartupSec。
      # Persistent は OnCalendar 専用なので単調タイマーでは指定しない
      OnStartupSec = "1min";
      OnUnitActiveSec = "10min";
      # 気象庁へのアクセスが毎回同じ秒に集中しないよう散らす
      RandomizedDelaySec = "2min";
    };

    Install.WantedBy = ["timers.target"];
  };

  systemd.user.services.eww = {
    Unit = {
      Description = "eww daemon (デスクトップ背景ダッシュボード)";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session.target"];
      Wants = ["graphical-session.target"];
      ConditionEnvironment = "WAYLAND_DISPLAY";
      # eww の設定監視は Modify イベントしか見ず、HM の symlink 差し替えでは
      # 再読込されない。内容が変わったら sd-switch に restart させる。
      # このオプションの型は listOf (either package str) なのでリストで渡す
      "X-Restart-Triggers" = ["${./eww.yuck}" "${./eww.scss}"];
      # 設定エラーで無限再起動ループに入らないよう上限を設ける
      StartLimitIntervalSec = 300;
      StartLimitBurst = 5;
    };

    Service = {
      # defpoll は /bin/sh 経由で実行されるため、参照するコマンドを PATH に固定する
      Environment = [
        "PATH=${lib.makeBinPath [dashboardData dashboardLive dashboardGpu]}"
      ];
      ExecStart = "${pkgs.eww}/bin/eww daemon --no-daemonize --force-wayland";
      ExecStartPost = "${dashboardOpen}/bin/dashboard-open";
      Restart = "on-failure";
      RestartSec = 2;
    };

    Install.WantedBy = ["graphical-session.target"];
  };
}
