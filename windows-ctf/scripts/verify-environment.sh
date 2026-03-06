#!/usr/bin/env bash
set -euo pipefail

errors=0

check_cmd() {
    local cmd="$1"
    if command -v "${cmd}" >/dev/null 2>&1; then
        printf '[OK] %s\n' "${cmd}"
    else
        printf '[NG] %s (missing)\n' "${cmd}"
        errors=$((errors + 1))
    fi
}

check_cmd git
check_cmd nmap
check_cmd sqlmap
check_cmd gdb
check_cmd radare2
check_cmd binwalk
check_cmd wireshark
check_cmd python3
check_cmd zsh
check_cmd tmux

if grep -qi "microsoft" /proc/version 2>/dev/null; then
    echo "[INFO] Environment: WSL"
else
    echo "[INFO] Environment: non-WSL (likely VM or bare metal)"
fi

if [[ ${errors} -gt 0 ]]; then
    echo "Verification failed with ${errors} missing commands."
    exit 1
fi

echo "Verification passed."
