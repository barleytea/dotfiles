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

  system.stateVersion = 5;
}
