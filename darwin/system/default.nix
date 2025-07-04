{pkgs, ...}: {
  imports = [ ../common.nix ];
  system = {
    defaults = {
      NSGlobalDomain = {
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
        ApplePressAndHoldEnabled = false;
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
      };
      dock = {
        autohide = true;
        show-recents = false;
        orientation = "left";
      };
      trackpad = {
        Clicking = true;
        TrackpadThreeFingerDrag = true;
      };
    };
  };
}
