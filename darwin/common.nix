# nix-darwin 共通設定
{ ... }: {
  nix = {
    optimise.automatic = true;
    settings = {
      experimental-features = "nix-command flakes";
      max-jobs = 8;
      trusted-users = [ "root" "miyoshi_s" ];
    };
  };

  # nix-darwinの新しいバージョン(unstable)で必須項目（homebrew、system.defaults等に必要）
  # ローカル環境、CI環境のどちらでも動作するように環境変数から取得
  system.primaryUser =
    if builtins.getEnv "USER" == ""
    then "miyoshi_s"
    else builtins.getEnv "USER";

  # Homebrewコマンドを実行するユーザーを指定
  # これによりsudo実行時でもHomebrewは通常ユーザーとして実行される
  homebrew.user = "miyoshi_s";

  system.stateVersion = 5;
}
