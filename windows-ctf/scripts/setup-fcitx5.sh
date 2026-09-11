#!/usr/bin/env bash
# fcitx5 + Mozc の日本語入力設定を配備する（WSLg 上の GUI アプリ全般向け）。
# パッケージ本体は manifests/gui.txt（fcitx5, fcitx5-mozc, fonts-noto-cjk 等）で導入する。
#
# nixos/home-manager/fcitx5/default.nix と同じプロファイル・トリガーキー設定を
# 手書きで再現している（Nix 管理外の Kali/WSL 環境のため）。挙動を変える場合は
# 両方を同期させること。ただし DisabledAddons=wayland は WSLg 固有の回避策
# なので同期しない（NixOS 側は Hyprland 等の実 Wayland コンポジタを使うため
# 不要、むしろ無効化すべきではない）。
set -euo pipefail

FCITX5_CONFIG_DIR="${HOME}/.config/fcitx5"

echo "==> Writing fcitx5 profile (Mozc default, layout us)..."
mkdir -p "${FCITX5_CONFIG_DIR}"
cat > "${FCITX5_CONFIG_DIR}/profile" <<'EOF'
[Groups/0]
Name=Default
Default Layout=us
Default Input Method=mozc

[Groups/0/Items/0]
Name=keyboard-us
Layout=us

[Groups/0/Items/1]
Name=mozc
Layout=

[GroupOrder]
0=Default
EOF

echo "==> Writing fcitx5 config (trigger keys: Control+space / Zenkaku_Hankaku / Hangul)..."
cat > "${FCITX5_CONFIG_DIR}/config" <<'EOF'
[Hotkey]
# Enumerate when press trigger key repeatedly
EnumerateWithTriggerKeys=True
# Enumerate Input Method Forward
EnumerateForwardKeys=
# Enumerate Input Method Backward
EnumerateBackwardKeys=
# Skip first input method while enumerating
EnumerateSkipFirst=False
# Time limit in milliseconds for triggering modifier key shortcuts
ModifierOnlyKeyTimeout=250

[Hotkey/TriggerKeys]
0=Control+space
1=Zenkaku_Hankaku
2=Hangul

[Hotkey/AltTriggerKeys]
0=Shift_L

[Hotkey/EnumerateGroupForwardKeys]
0=Super+space

[Hotkey/EnumerateGroupBackwardKeys]
0=Shift+Super+space

[Hotkey/ActivateKeys]
0=Hangul_Hanja

[Hotkey/DeactivateKeys]
0=Hangul_Romaja

[Hotkey/PrevPage]
0=Up

[Hotkey/NextPage]
0=Down

[Hotkey/PrevCandidate]
0=Shift+Tab

[Hotkey/NextCandidate]
0=Tab

[Hotkey/TogglePreedit]
0=Control+Alt+P

[Behavior]
# Active By Default
ActiveByDefault=True
# Reset state on Focus In
resetStateWhenFocusIn=No
# Share Input State
ShareInputState=All
# Show preedit in application
PreeditEnabledByDefault=True
# Show Input Method Information when switch input method
ShowInputMethodInformation=True
# Show Input Method Information when changing focus
showInputMethodInformationWhenFocusIn=False
# Show compact input method information
CompactInputMethodInformation=True
# Show first input method information
ShowFirstInputMethodInformation=True
# Default page size
DefaultPageSize=5
# Override Xkb Option
OverrideXkbOption=False
# Custom Xkb Option
CustomXkbOption=
# Force Enabled Addons
EnabledAddons=
# Force Disabled Addons
#
# wayland アドオンを無効化する。WSLg のコンポジタ（Weston ベース）は
# zwp_input_method_v1 の bind を拒否するため、有効なままだと fcitx5 が
# Wayland 接続エラーを起点に dbus/dbusfrontend/classicui/xim を含む
# 全アドオンを巻き添えでアンロードしてしまい、本来 Wayland に依存しない
# はずの XWayland + D-Bus 経由の GTK/Qt 連携まで巻き込んで壊れる。
DisabledAddons=wayland
# Preload input method to be used by default
PreloadInputMethod=True
# Allow input method in the password field
AllowInputMethodForPassword=False
# Show preedit text when typing password
ShowPreeditForPassword=False
# Interval of saving user data in minutes
AutoSavePeriod=30
EOF

echo ""
echo "==> fcitx5 setup complete."
echo "    Package install (if not already done): make install-all  (manifests/gui.txt)"
echo "    GUI アプリから使うには GTK_IM_MODULE=fcitx5 / QT_IM_MODULE=fcitx5 /"
echo "    XMODIFIERS=@im=fcitx5 を環境変数に設定し、"
echo "    fcitx5 -D --replace --disable wayland & (WSLg では -d ではなく -D + シェルの & で起動すること)"
echo "    orca-ide はこれを自動で行う（install-orca.sh 参照）。"
echo "    切り替えキー: Ctrl+Space / 半角全角 / Shift（左）"
