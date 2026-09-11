#!/usr/bin/env bash
set -euo pipefail

readonly ORCA_RELEASE_API="${ORCA_RELEASE_API:-https://api.github.com/repos/stablyai/orca/releases/latest}"
readonly ORCA_DATA_DIR="${ORCA_DATA_DIR:-${XDG_DATA_HOME:-${HOME}/.local/share}/orca}"
readonly ORCA_BIN_DIR="${ORCA_BIN_DIR:-${HOME}/.local/bin}"
readonly ORCA_DESKTOP_DIR="${ORCA_DESKTOP_DIR:-${XDG_DATA_HOME:-${HOME}/.local/share}/applications}"
readonly ORCA_APPIMAGE_PATH="${ORCA_DATA_DIR}/orca-linux.AppImage"

install_launcher() {
    local launcher_path="${ORCA_BIN_DIR}/orca-ide"

    mkdir -p "${ORCA_BIN_DIR}" "${ORCA_DESKTOP_DIR}"
    # このランチャーは常にこの関数自身が生成する通常ファイルなので、
    # 「symlink でなければ既存ファイルとして保護する」というガードは
    # 常に自分自身の前回出力を拒否してしまい、--repair-launcher を含む
    # 再生成が永久に失敗するバグだった。ここは無条件に上書きしてよい。
    rm -f "${launcher_path}"
    {
        printf '%s\n' '#!/usr/bin/env bash' 'set -euo pipefail'
        printf 'readonly appimage_path=%q\n' "${ORCA_APPIMAGE_PATH}"
        printf '%s\n' \
            '# 日本語入力を有効化する（setup-fcitx5.sh でプロファイル配備済みの前提）。' \
            'export GTK_IM_MODULE=fcitx5' \
            'export QT_IM_MODULE=fcitx5' \
            'export XMODIFIERS=@im=fcitx5' \
            'export SDL_IM_MODULE=fcitx5' \
            'if command -v fcitx5 >/dev/null 2>&1 && ! pgrep -x fcitx5 >/dev/null 2>&1; then' \
            '    # -d（内部デーモン化 / fork）だと WSLg 環境で何かが壊れて' \
            '    # GTK 側から一切キーイベントを受け取れなくなる。-D（非デーモン化）' \
            '    # をシェルの & でバックグラウンド化する形でないと機能しない。' \
            '    # --disable wayland は WSLg の compositor が zwp_input_method_v1 の' \
            '    # bind を拒否し、それを起点に dbus/xim を含む全アドオンが巻き添えで' \
            '    # アンロードされる問題の回避策（config ファイルの DisabledAddons= は' \
            '    # 反映されないため CLI フラグで直接指定する）。' \
            '    fcitx5 -D --replace --disable wayland >/dev/null 2>&1 &' \
            '    disown' \
            'fi' \
            '' \
            'if [[ -e /dev/fuse ]] && {' \
            '    command -v fusermount >/dev/null 2>&1 ||' \
            '        command -v fusermount3 >/dev/null 2>&1' \
            '}; then' \
            '    exec "${appimage_path}" "$@"' \
            'fi' \
            'exec "${appimage_path}" --appimage-extract-and-run "$@"'
    } > "${launcher_path}"
    chmod 0755 "${launcher_path}"

    local desktop_file="${ORCA_DESKTOP_DIR}/orca.desktop"
    printf '%s\n' \
        '[Desktop Entry]' \
        'Type=Application' \
        'Name=Orca' \
        'Comment=Agent development environment' \
        "Exec=\"${launcher_path}\" %U" \
        "TryExec=${launcher_path}" \
        'Icon=applications-development' \
        'Categories=Development;IDE;' \
        'Terminal=false' \
        'StartupNotify=true' \
        > "${desktop_file}"
    chmod 0644 "${desktop_file}"

    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "${ORCA_DESKTOP_DIR}" >/dev/null 2>&1 || true
    fi
}

if [[ "${1:-}" == '--repair-launcher' ]]; then
    if [[ ! -x "${ORCA_APPIMAGE_PATH}" ]]; then
        echo "Error: installed AppImage not found: ${ORCA_APPIMAGE_PATH}" >&2
        exit 1
    fi
    install_launcher
    echo 'Orca launcher repaired. Run: orca-ide'
    exit 0
elif [[ $# -gt 0 ]]; then
    echo "Usage: $0 [--repair-launcher]" >&2
    exit 1
fi

for command_name in curl jq sha256sum; do
    if ! command -v "${command_name}" >/dev/null 2>&1; then
        echo "Error: required command not found: ${command_name}" >&2
        exit 1
    fi
done

case "$(uname -m)" in
    x86_64)
        asset_name='orca-linux.AppImage'
        ;;
    aarch64 | arm64)
        asset_name='orca-linux-arm64.AppImage'
        ;;
    *)
        echo "Error: unsupported architecture: $(uname -m)" >&2
        exit 1
        ;;
esac

if grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
    cat <<'EOM'
Note: WSL detected. The recommended setup is the Windows Orca app with a
WSL-hosted agent account. Continuing with the Linux AppImage for WSLg.
EOM
fi

mkdir -p "${ORCA_DATA_DIR}"
temporary_dir="$(mktemp -d "${ORCA_DATA_DIR}/.install.XXXXXX")"
trap 'rm -rf -- "${temporary_dir}"' EXIT

echo '==> Resolving the latest stable Orca release'
release_json="$(
    curl --fail --location --silent --show-error --retry 3 \
        -H 'Accept: application/vnd.github+json' \
        -H 'X-GitHub-Api-Version: 2022-11-28' \
        "${ORCA_RELEASE_API}"
)"

release_tag="$(jq -er '.tag_name' <<<"${release_json}")"
asset_url="$(
    jq -er --arg asset_name "${asset_name}" \
        '.assets[] | select(.name == $asset_name) | .browser_download_url' \
        <<<"${release_json}"
)"
asset_digest="$(
    jq -r --arg asset_name "${asset_name}" \
        '.assets[] | select(.name == $asset_name) | (.digest // empty)' \
        <<<"${release_json}"
)"

if [[ "${asset_digest}" != sha256:* ]]; then
    echo "Error: GitHub did not provide a SHA-256 digest for ${asset_name}" >&2
    exit 1
fi

download_path="${temporary_dir}/${asset_name}"
echo "==> Downloading Orca ${release_tag} (${asset_name})"
curl --fail --location --show-error --retry 3 \
    --output "${download_path}" "${asset_url}"

expected_sha256="${asset_digest#sha256:}"
actual_sha256="$(sha256sum "${download_path}" | cut -d ' ' -f 1)"
if [[ "${actual_sha256}" != "${expected_sha256}" ]]; then
    echo 'Error: Orca AppImage checksum verification failed' >&2
    exit 1
fi

chmod 0755 "${download_path}"
mv -f "${download_path}" "${ORCA_APPIMAGE_PATH}"
install_launcher

cat <<EOM
Orca ${release_tag} installed.
Launch it from the desktop menu or run: orca-ide

The launcher uses FUSE when available and automatically falls back to the
AppImage extraction mode when WSL has no /dev/fuse device.
EOM
