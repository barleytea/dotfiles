{...}: {
  home.file.".config/borders/bordersrc" = {
    source = ./bordersrc;
    executable = true;
  };

  launchd.agents.borders = {
    enable = true;
    config = {
      ProgramArguments = [ "/opt/homebrew/bin/borders" ];
      KeepAlive = {
        Crashed = true;
        SuccessfulExit = false;
      };
      ProcessType = "Interactive";
      RunAtLoad = true;
      EnvironmentVariables = {
        PATH = "/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      };
    };
  };
}
