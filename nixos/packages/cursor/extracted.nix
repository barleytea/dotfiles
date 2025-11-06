{ lib
, stdenv
, fetchurl
, appimageTools
, autoPatchelfHook
, asar
, makeWrapper
, copyDesktopItems
, makeDesktopItem
, wrapGAppsHook3
, bash
, ripgrep
, glib
, gtk3
, gnome
, gsettings-desktop-schemas
, libsecret
, libXScrnSaver
, libxshmfence
, libxkbfile
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
, patchelf
}:

let
  pname = "cursor";
  version = "2.0.34";

  src = fetchurl {
    url = "https://downloads.cursor.com/production/45fd70f3fe72037444ba35c9e51ce86a1977ac11/linux/x64/Cursor-${version}-x86_64.AppImage";
    hash = "sha256-x51N2BttMkfKwH4/Uxn/ZNFVPZbaNdsZm8BFFIMmxBM=";
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
    makeWrapper
    copyDesktopItems
    wrapGAppsHook3
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

    # Create a wrapper script that patches cursor-agent node binaries
    cat > "$out/bin/.cursor-real" <<'EOF'
#!/usr/bin/env bash
# Patch cursor-agent node binaries if they exist and haven't been patched yet
CURSOR_AGENT_DIR="$HOME/.local/share/cursor-agent/versions"
if [ -d "$CURSOR_AGENT_DIR" ]; then
  for version_dir in "$CURSOR_AGENT_DIR"/*/; do
    if [ -f "$version_dir/node" ] && [ ! -f "$version_dir/.patched" ]; then
      echo "Patching cursor-agent node binary: $version_dir/node" >&2
      chmod +w "$version_dir/node" 2>/dev/null || true
      PATCHELF_BIN/patchelf \
        --set-interpreter "DYNAMIC_LINKER" \
        --set-rpath "RPATH" \
        "$version_dir/node" 2>/dev/null && touch "$version_dir/.patched" || true
    fi
  done
fi

# Run the actual cursor binary
exec CURSOR_BIN "$@"
EOF

    substituteInPlace "$out/bin/.cursor-real" \
      --replace-fail "PATCHELF_BIN" "${patchelf}/bin" \
      --replace-fail "DYNAMIC_LINKER" "${stdenv.cc.bintools.dynamicLinker}" \
      --replace-fail "RPATH" "${lib.makeLibraryPath [ stdenv.cc.cc.lib ]}" \
      --replace-fail "CURSOR_BIN" "$out/lib/cursor/bin/cursor"

    chmod +x "$out/bin/.cursor-real"

    # Rename for wrapGAppsHook to wrap
    mv "$out/bin/.cursor-real" "$out/bin/cursor"

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
