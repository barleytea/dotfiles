{
  pkgs,
  homePath,
  profileMapPath,
}: let
  awsReadonly = pkgs.writeShellScriptBin "aws-readonly" ''
    export PATH="${pkgs.python3}/bin:$PATH"
    exec ${pkgs.bash}/bin/bash ${./aws-readonly.sh} \
      ${pkgs.lib.escapeShellArg profileMapPath} \
      ${pkgs.lib.escapeShellArg homePath} \
      ${./profile_map.py} ${./response_filter.py} "$@"
  '';
  awsReadonlyGuard = pkgs.writeShellScriptBin "aws-readonly-guard" ''
    exec ${pkgs.python3}/bin/python3 ${./guard.py}
  '';
in {
  inherit awsReadonly awsReadonlyGuard;
}
