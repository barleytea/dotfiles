# GPU 温度（摂氏の整数、取得できなければ "--"）
#
# NVIDIA の GPU は hwmon に温度を出さないため nvidia-smi から取る。
# nvidia-smi は実行中のカーネルモジュールと版が一致していなければならないので、
# Nix store のパッケージではなく NixOS のランタイムパスを直接叩く。

readonly NVIDIA_SMI=/run/current-system/sw/bin/nvidia-smi

temp=''
if [ -x "$NVIDIA_SMI" ]; then
    temp="$("$NVIDIA_SMI" --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null |
        head -n 1 | tr -d '[:space:]')"
fi

case "$temp" in
    '' | *[!0-9]*) printf -- '--' ;;
    *) printf '%s' "$temp" ;;
esac
