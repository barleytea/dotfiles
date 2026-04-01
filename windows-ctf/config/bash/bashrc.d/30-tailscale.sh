#!/usr/bin/env bash
# Tailscale utilities

# Taildrop: ファイルを別デバイスに送る
# 使い方: tfile <file> <device>
#   device は `tailscale status` で確認できるホスト名
function tfile() {
  if [[ $# -lt 2 ]]; then
    echo "Usage: tfile <file> <device>" >&2
    echo "       Devices: $(tailscale status --json 2>/dev/null | jq -r '.Peer[].HostName' 2>/dev/null | tr '\n' ' ')" >&2
    return 1
  fi
  tailscale file cp "$1" "${2}:"
}

# scp wrapper over Tailscale SSH
# 使い方: tscp <file> <device>:<path>
#         tscp <device>:<path> <local_path>
function tscp() {
  if [[ $# -lt 2 ]]; then
    echo "Usage: tscp <src> <dst>" >&2
    echo "       e.g.: tscp file.txt macbook:/tmp/" >&2
    echo "       e.g.: tscp macbook:/tmp/file.txt ." >&2
    return 1
  fi
  scp -o StrictHostKeyChecking=no "$@"
}

# rsync wrapper over Tailscale SSH
# 使い方: tsync <src> <device>:<dst>
function tsync() {
  if [[ $# -lt 2 ]]; then
    echo "Usage: tsync <src> <device>:<dst>" >&2
    echo "       e.g.: tsync ./loot/ macbook:~/loot/" >&2
    return 1
  fi
  rsync -avz --progress -e "ssh -o StrictHostKeyChecking=no" "$@"
}

# 接続中のデバイス一覧
alias tslist='tailscale status'
