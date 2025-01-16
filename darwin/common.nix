{
  nix = {
    optimise.automatic = true;
    settings = {
      experimental-features = "nix-command flakes";
      extra-trusted-users = ["miyoshi_s"];
      max-jobs = 8;
    };
  };
  system.stateVersion = 5;
  services.nix-daemon.enable = true;
}
