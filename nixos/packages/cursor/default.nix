{ pkgs, ... }:
let
  pname = "cursor";
  version = "1.6.45";

  src = pkgs.fetchurl {
    url = "https://downloads.cursor.com/production/3ccce8f55d8cca49f6d28b491a844c699b8719a3/linux/x64/Cursor-1.6.45-x86_64.AppImage";
    hash = "sha256-MlrevU26gD6hpZbqbdKQwnzJbm5y9SVSb3d0BGnHtpc=";
  };

  appimageContents = pkgs.appimageTools.extract { inherit pname version src; };
in with pkgs;
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -m 444 -D ${appimageContents}/${pname}.desktop -t $out/share/applications
    substituteInPlace $out/share/applications/${pname}.desktop \
      --replace-quiet 'Exec=AppRun' 'Exec=${pname}'
    cp -r ${appimageContents}/usr/share/icons $out/share

    if [ -e ${appimageContents}/AppRun ]; then
      install -m 755 -D ${appimageContents}/AppRun $out/bin/${pname}-${version}
      if [ ! -L $out/bin/${pname} ]; then
        ln -s $out/bin/${pname}-${version} $out/bin/${pname}
      fi
    else
      echo "Error: Binary not found in extracted AppImage contents."
      exit 1
    fi
  '';

  extraBwrapArgs = [
    "--bind-try /etc/nixos/ /etc/nixos/"
    # Bind home directory for cursor-agent
    "--bind-try \${HOME}/.local/share/cursor-agent \${HOME}/.local/share/cursor-agent"
  ];
  dieWithParent = false;

  extraPkgs = pkgs: [
    unzip
    autoPatchelfHook
    stdenv.cc.cc.lib
    openssl
    icu
    zlib
    # Node.js runtime for cursor-agent
    nodejs_20
  ];

  meta = with lib; {
    description = "Cursor AI-powered code editor";
    homepage = "https://cursor.com";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
  };
}
