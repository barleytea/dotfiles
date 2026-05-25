{ config, lib, ... }:

{
  systemd.user.services.agent-sin-discord = {
    Unit = {
      Description = "Agent-Sin Discord Bot";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };

    Service = {
      ExecStart = "${config.home.homeDirectory}/.npm-global/bin/agent-sin discord";
      Restart = "on-failure";
      RestartSec = "10s";
      Environment = [
        "PATH=${config.home.homeDirectory}/.local/share/mise/shims:${config.home.homeDirectory}/.npm-global/bin:/run/current-system/sw/bin:/usr/bin:/bin"
        "HOME=${config.home.homeDirectory}"
      ];
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
