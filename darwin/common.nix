{
  nix = {
    optimise.automatic = true;
    settings = {
      experimental-features = "nix-command flakes";
      max-jobs = 8;
    };
  };

  system = {
    stateVersion = 5;

    # nix-darwinの新しいバージョンで必須項目（homebrew、system.defaults等に必要）
    # ローカル環境、CI環境のどちらでも動作するように環境変数から取得
    primaryUser = if builtins.getEnv "USER" == "" then "miyoshi_s" else builtins.getEnv "USER";
  };
}
