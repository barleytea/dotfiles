{ lib
, stdenv
, fetchurl
, appimageTools
, autoPatchelfHook
, asar
, makeWrapper
, copyDesktopItems
, makeDesktopItem
, wrapGAppsHook
, bash
, ripgrep
, glib
, gtk3
, gnome
, gsettings-desktop-schemas
, libsecret
, libXScrnSaver
, libxshmfence
, alsa-lib
, at-spi2-atk
, at-spi2-core
, cairo
, cups
, dbus
, expat
, gdk-pixbuf
, libGL
, libappindicator-gtk3
, libdrm
, libnotify
, libpulseaudio
, libuuid
, libxcb
, libxkbcommon
, mesa
, nspr
, nss
, pango
, systemd
, wayland
, xorg
, zlib
, fontconfig
, freetype
, libglvnd
, libdbusmenu
}:

let
  pname = "cursor";
  version = "1.6.45";

  src = fetchurl {
    url = "https://downloads.cursor.com/production/3ccce8f55d8cca49f6d28b491a844c699b8719a3/linux/x64/Cursor-${version}-x86_64.AppImage";
    hash = "sha256-MlrevU26gD6hpZbqbdKQwnzJbm5y9SVSb3d0BGnHtpc=";
  };

  appimageContents = appimageTools.extract {
    inherit pname version src;
  };

in stdenv.mkDerivation {
  inherit pname version;

  src = appimageContents;
  sourceRoot = "${appimageContents.name}/usr/share/cursor";

  nativeBuildInputs = [
    autoPatchelfHook
    asar
    copyDesktopItems
    wrapGAppsHook
  ];

  buildInputs = [
    libsecret
    libXScrnSaver
    libxshmfence
    alsa-lib
    at-spi2-core
    cups
    mesa
    nss
    nspr
    systemd
    libxkbfile
  ];

  runtimeDependencies = [
    systemd
    fontconfig
    libdbusmenu
    wayland
    libsecret
  ];

  dontBuild = true;
  dontConfigure = true;

  postPatch = ''
    # Fix asar package
    packed="resources/app/node_modules.asar"
    unpacked="resources/app/node_modules"
    asar extract "$packed" "$unpacked"

    # Patch sudo-prompt
    substituteInPlace $unpacked/@vscode/sudo-prompt/index.js \
      --replace-fail "/usr/bin/pkexec" "/run/wrappers/bin/pkexec" \
      --replace-fail "/bin/bash" "${bash}/bin/bash"

    # Repack
    rm -rf "$packed"
    ln -rs "$unpacked" "$packed"

    # Fix ripgrep
    rm resources/app/node_modules/@vscode/ripgrep/bin/rg
    ln -s ${ripgrep}/bin/rg resources/app/node_modules/@vscode/ripgrep/bin/rg
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib/cursor" "$out/bin"
    cp -r ./* "$out/lib/cursor"

    ln -s "$out/lib/cursor/bin/cursor" "$out/bin/cursor"

    mkdir -p "$out/share/pixmaps"
    cp "$out/lib/cursor/resources/app/resources/linux/code.png" "$out/share/pixmaps/cursor.png"

    # Remove problematic encryption module
    rm -rf $out/lib/cursor/resources/app/node_modules/vscode-encrypt

    runHook postInstall
  '';

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libdbusmenu ]}
      --prefix PATH : ${glib}/bin
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true --wayland-text-input-version=3}}"
      --add-flags '--update=false'
    )
  '';

  postFixup = ''
    # Add required libraries
    patchelf \
      --add-needed ${libglvnd}/lib/libGLESv2.so.2 \
      --add-needed ${libglvnd}/lib/libGL.so.1 \
      --add-needed ${libglvnd}/lib/libEGL.so.1 \
      $out/lib/cursor/cursor
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "cursor";
      exec = "cursor %U";
      icon = "cursor";
      desktopName = "Cursor";
      genericName = "Text Editor";
      comment = "Cursor AI-powered code editor";
      categories = [ "Development" "IDE" ];
      mimeTypes = [ "text/plain" "inode/directory" ];
    })
  ];

  meta = with lib; {
    description = "Cursor AI-powered code editor";
    homepage = "https://cursor.com";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "cursor";
  };
}
