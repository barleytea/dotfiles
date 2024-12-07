{
  nix = {
    optimise.automatic = true;
    settings = {
      experimental-features = "nix-command flakes";
      max-jobs = 8;
    };
  };
  system.stateVersion = 5;
  services.nix-daemon.enable = true;
}
