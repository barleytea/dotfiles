{...}: {
  plugins = {
    render-markdown = {
      enable = true;
      settings = {
        code = {
          style = "full"; # 背景 + 言語ラベル + ボーダー
          width = "full"; # ウィンドウ全幅に背景
          border = "thick"; # 太いボーダー表示
          left_pad = 2;
          right_pad = 2;
          above = "▄";
          below = "▀";
          sign = true;
        };
        heading = {
          sign = true;
          width = "full";
          border = true;
        };
      };
    };
  };
}
