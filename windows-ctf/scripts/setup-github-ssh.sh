#!/usr/bin/env bash
set -euo pipefail

EMAIL="barleytea362@gmail.com"
KEY_PATH="$HOME/.ssh/id_ed25519"
REPO_DIR="$(git -C "$(dirname "$0")/.." rev-parse --show-toplevel 2>/dev/null || true)"

# 1. SSH キー生成（なければ）
if [[ ! -f "$KEY_PATH" ]]; then
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY_PATH" -N ""
    echo "✓ SSH key generated: $KEY_PATH"
else
    echo "✓ SSH key already exists: $KEY_PATH"
fi

# 2. SSH エージェント起動・キー登録
if ! ssh-add -l &>/dev/null; then
    eval "$(ssh-agent -s)"
fi
ssh-add "$KEY_PATH" 2>/dev/null || true

# 3. ~/.zshrc に SSH エージェント自動起動を追記（べき等）
ZSHRC="$HOME/.zshrc"
MARKER="# ssh-agent auto-start (added by setup-github-ssh.sh)"
if ! grep -qF "$MARKER" "$ZSHRC" 2>/dev/null; then
    cat >> "$ZSHRC" << 'EOF'

# ssh-agent auto-start (added by setup-github-ssh.sh)
if [ -z "$SSH_AUTH_SOCK" ] || ! ssh-add -l &>/dev/null; then
    eval "$(ssh-agent -s)" > /dev/null
    ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null || true
fi
EOF
    echo "✓ SSH agent auto-start added to $ZSHRC"
fi

# 4. 公開鍵を表示
echo ""
echo "=== Add this public key to GitHub (Settings > SSH and GPG keys) ==="
cat "${KEY_PATH}.pub"
echo "=================================================================="
echo ""
echo "Press Enter after adding the key to GitHub..."
read -r

# 5. 接続テスト
echo "Testing connection to GitHub..."
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo "✓ GitHub SSH connection successful"
else
    echo "⚠ Connection test returned non-zero (this is normal for GitHub)"
    ssh -T git@github.com 2>&1 || true
fi

# 6. リモート URL を SSH 形式に変更
if [[ -n "$REPO_DIR" ]]; then
    CURRENT_REMOTE=$(git -C "$REPO_DIR" remote get-url origin 2>/dev/null || true)
    if [[ "$CURRENT_REMOTE" == https://github.com/* ]]; then
        SSH_REMOTE=$(echo "$CURRENT_REMOTE" | sed 's|https://github.com/|git@github.com:|')
        echo ""
        echo "Change remote URL to SSH?"
        echo "  From: $CURRENT_REMOTE"
        echo "  To:   $SSH_REMOTE"
        read -rp "Proceed? [Y/n] " ans
        if [[ "${ans:-Y}" =~ ^[Yy]$ ]]; then
            git -C "$REPO_DIR" remote set-url origin "$SSH_REMOTE"
            echo "✓ Remote URL updated"
        fi
    else
        echo "✓ Remote URL is already SSH or non-HTTPS: $CURRENT_REMOTE"
    fi
fi

echo ""
echo "Done. Run 'git push' to verify."
