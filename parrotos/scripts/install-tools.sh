#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Update mode
UPDATE_MODE=false
if [[ "${1:-}" == "--update" ]]; then
    UPDATE_MODE=true
fi

echo -e "${BLUE}=== Installing non-apt tools ===${NC}\n"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to get installed version
get_version() {
    local cmd="$1"
    local version_flag="${2:---version}"

    if command_exists "$cmd"; then
        $cmd "$version_flag" 2>/dev/null | head -n1 || echo "unknown"
    else
        echo "not installed"
    fi
}

# mise
echo -e "${BLUE}[mise]${NC}"
if command_exists mise; then
    echo -e "${GREEN}✓${NC} mise is already installed: $(get_version mise)"
    if [[ "$UPDATE_MODE" == true ]]; then
        echo "Updating mise..."
        mise self-update || true
    fi
else
    echo "Installing mise..."
    curl https://mise.run | sh
    export PATH="$HOME/.local/bin:$PATH"
fi

# starship
echo -e "\n${BLUE}[starship]${NC}"
if command_exists starship; then
    echo -e "${GREEN}✓${NC} starship is already installed: $(get_version starship)"
else
    echo "Installing starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# sheldon
echo -e "\n${BLUE}[sheldon]${NC}"
if command_exists sheldon; then
    echo -e "${GREEN}✓${NC} sheldon is already installed: $(get_version sheldon)"
else
    echo "Installing sheldon..."
    curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh \
        | bash -s -- --repo rossmacarthur/sheldon --to ~/.local/bin
fi

# atuin
echo -e "\n${BLUE}[atuin]${NC}"
if command_exists atuin; then
    echo -e "${GREEN}✓${NC} atuin is already installed: $(get_version atuin)"
else
    echo "Installing atuin..."
    curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
fi

# zoxide
echo -e "\n${BLUE}[zoxide]${NC}"
if command_exists zoxide; then
    echo -e "${GREEN}✓${NC} zoxide is already installed: $(get_version zoxide)"
else
    echo "Installing zoxide..."
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
fi

# zellij
echo -e "\n${BLUE}[zellij]${NC}"
if command_exists zellij; then
    echo -e "${GREEN}✓${NC} zellij is already installed: $(get_version zellij)"
else
    echo "Installing zellij..."
    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" ]]; then
        ZELLIJ_ARCH="x86_64"
    elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
        ZELLIJ_ARCH="aarch64"
    else
        echo -e "${RED}✗${NC} Unsupported architecture: $ARCH"
        exit 1
    fi

    ZELLIJ_VERSION=$(curl -fsSL https://api.github.com/repos/zellij-org/zellij/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    ZELLIJ_URL="https://github.com/zellij-org/zellij/releases/download/v${ZELLIJ_VERSION}/zellij-${ZELLIJ_ARCH}-unknown-linux-musl.tar.gz"

    mkdir -p ~/.local/bin
    curl -fL "$ZELLIJ_URL" | tar xz -C ~/.local/bin
    chmod +x ~/.local/bin/zellij
fi

# yazi
echo -e "\n${BLUE}[yazi]${NC}"
if command_exists yazi; then
    echo -e "${GREEN}✓${NC} yazi is already installed: $(get_version yazi)"
else
    echo "Installing yazi..."
    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" ]]; then
        YAZI_ARCH="x86_64"
    elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
        YAZI_ARCH="aarch64"
    else
        echo -e "${RED}✗${NC} Unsupported architecture: $ARCH"
        exit 1
    fi

    YAZI_VERSION=$(curl -fsSL https://api.github.com/repos/sxyazi/yazi/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    YAZI_URL="https://github.com/sxyazi/yazi/releases/download/v${YAZI_VERSION}/yazi-${YAZI_ARCH}-unknown-linux-musl.zip"

    TMP_DIR=$(mktemp -d)
    curl -fL "$YAZI_URL" -o "${TMP_DIR}/yazi.zip"
    unzip -q "${TMP_DIR}/yazi.zip" -d "${TMP_DIR}"
    mkdir -p ~/.local/bin
    mv "${TMP_DIR}"/yazi-*/yazi ~/.local/bin/
    chmod +x ~/.local/bin/yazi
    rm -rf "${TMP_DIR}"
fi

# eza
echo -e "\n${BLUE}[eza]${NC}"
if command_exists eza; then
    echo -e "${GREEN}✓${NC} eza is already installed: $(get_version eza)"
else
    echo "Installing eza..."
    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" ]]; then
        EZA_ARCH="x86_64"
    elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
        EZA_ARCH="aarch64"
    else
        echo -e "${RED}✗${NC} Unsupported architecture: $ARCH"
        exit 1
    fi

    EZA_VERSION=$(curl -fsSL https://api.github.com/repos/eza-community/eza/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    EZA_URL="https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_${EZA_ARCH}-unknown-linux-musl.tar.gz"

    mkdir -p ~/.local/bin
    curl -fL "$EZA_URL" | tar xz -C ~/.local/bin
    chmod +x ~/.local/bin/eza
fi

# delta (git-delta)
echo -e "\n${BLUE}[delta]${NC}"
if command_exists delta; then
    echo -e "${GREEN}✓${NC} delta is already installed: $(get_version delta)"
else
    echo "Installing delta..."
    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" ]]; then
        DELTA_ARCH="x86_64"
        DELTA_DEB_ARCH="amd64"
    elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
        DELTA_ARCH="aarch64"
        DELTA_DEB_ARCH="arm64"
    else
        echo -e "${RED}✗${NC} Unsupported architecture: $ARCH"
        exit 1
    fi

    DELTA_RELEASE_JSON=$(curl -fsSL https://api.github.com/repos/dandavison/delta/releases/latest)
    DELTA_TAG=$(printf '%s' "$DELTA_RELEASE_JSON" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    DELTA_VERSION="${DELTA_TAG#v}"
    DELTA_TGZ_URL=$(printf '%s' "$DELTA_RELEASE_JSON" \
        | grep -oE "https://[^\"[:space:]]*git-delta_${DELTA_VERSION}_${DELTA_ARCH}-unknown-linux-(musl|gnu)\\.tar\\.gz" \
        | head -n1 || true)

    if [[ -n "$DELTA_TGZ_URL" ]]; then
        TMP_DIR=$(mktemp -d)
        curl -fL "$DELTA_TGZ_URL" | tar xz -C "${TMP_DIR}"
        mkdir -p ~/.local/bin
        mv "${TMP_DIR}"/delta ~/.local/bin/
        chmod +x ~/.local/bin/delta
        rm -rf "${TMP_DIR}"
    else
        DELTA_DEB_URL=$(printf '%s' "$DELTA_RELEASE_JSON" \
            | grep -oE "https://[^\"[:space:]]*git-delta_${DELTA_VERSION}_${DELTA_DEB_ARCH}\\.deb" \
            | head -n1 || true)
        if [[ -z "$DELTA_DEB_URL" ]]; then
            echo -e "${RED}✗${NC} delta release asset not found for architecture: ${ARCH}"
            exit 1
        fi

        TMP_DIR=$(mktemp -d)
        curl -fL "$DELTA_DEB_URL" -o "${TMP_DIR}/delta.deb"
        sudo dpkg -i "${TMP_DIR}/delta.deb" || sudo apt-get install -f -y
        rm -rf "${TMP_DIR}"
    fi
fi

# ghq
echo -e "\n${BLUE}[ghq]${NC}"
if command_exists ghq; then
    echo -e "${GREEN}✓${NC} ghq is already installed: $(get_version ghq)"
else
    echo "Installing ghq..."
    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" ]]; then
        GHQ_ARCH="amd64"
    elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
        GHQ_ARCH="arm64"
    else
        echo -e "${RED}✗${NC} Unsupported architecture: $ARCH"
        exit 1
    fi

    GHQ_VERSION=$(curl -fsSL https://api.github.com/repos/x-motemen/ghq/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    GHQ_URL="https://github.com/x-motemen/ghq/releases/download/v${GHQ_VERSION}/ghq_linux_${GHQ_ARCH}.zip"

    TMP_DIR=$(mktemp -d)
    curl -fL "$GHQ_URL" -o "${TMP_DIR}/ghq.zip"
    unzip -q "${TMP_DIR}/ghq.zip" -d "${TMP_DIR}"
    mkdir -p ~/.local/bin
    mv "${TMP_DIR}"/ghq_*/ghq ~/.local/bin/
    chmod +x ~/.local/bin/ghq
    rm -rf "${TMP_DIR}"
fi

# lazygit
echo -e "\n${BLUE}[lazygit]${NC}"
if command_exists lazygit; then
    echo -e "${GREEN}✓${NC} lazygit is already installed: $(get_version lazygit)"
else
    echo "Installing lazygit..."
    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" ]]; then
        LAZYGIT_ARCH="x86_64"
    elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
        LAZYGIT_ARCH="arm64"
    else
        echo -e "${RED}✗${NC} Unsupported architecture: $ARCH"
        exit 1
    fi

    LAZYGIT_VERSION=$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    LAZYGIT_URL="https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_${LAZYGIT_ARCH}.tar.gz"

    TMP_DIR=$(mktemp -d)
    curl -fL "$LAZYGIT_URL" | tar xz -C "${TMP_DIR}"
    mkdir -p ~/.local/bin
    mv "${TMP_DIR}"/lazygit ~/.local/bin/
    chmod +x ~/.local/bin/lazygit
    rm -rf "${TMP_DIR}"
fi

# Cursor (GUI エディタ - CI ではスキップ)
echo -e "\n${BLUE}[cursor]${NC}"
if [[ "${CI:-}" == "true" ]]; then
    echo -e "${YELLOW}Skipping cursor (CI environment)${NC}"
elif command_exists cursor; then
    echo -e "${GREEN}✓${NC} cursor is already installed: $(get_version cursor)"
else
    echo "Installing cursor..."
    if curl -fsSL https://cursor.com/install | bash; then
        echo -e "${GREEN}✓${NC} cursor installed"
    else
        echo -e "${YELLOW}⚠${NC} cursor install failed (manual install: https://cursor.com)${NC}"
    fi
fi

# Claude Code CLI (agent)
echo -e "\n${BLUE}[claude]${NC}"
if [[ "${CI:-}" == "true" ]]; then
    echo -e "${YELLOW}Skipping claude (CI environment)${NC}"
elif command_exists claude; then
    echo -e "${GREEN}✓${NC} claude is already installed: $(get_version claude)"
else
    echo "Installing claude..."
    if curl -fsSL https://claude.ai/install.sh | bash; then
        echo -e "${GREEN}✓${NC} claude installed"
    else
        echo -e "${YELLOW}⚠${NC} claude install failed (manual install: https://claude.ai/download)${NC}"
    fi
fi

# OpenAI Codex CLI
echo -e "\n${BLUE}[codex]${NC}"
if command_exists codex; then
    echo -e "${GREEN}✓${NC} codex is already installed: $(get_version codex)"
else
    echo "Installing codex..."
    if command_exists npm; then
        npm install -g @openai/codex
        echo -e "${GREEN}✓${NC} codex installed"
    elif command_exists mise; then
        mise x node@lts -- npm install -g @openai/codex
        echo -e "${GREEN}✓${NC} codex installed via mise"
    else
        echo -e "${YELLOW}⚠${NC} npm/mise not found; skipping codex install${NC}"
    fi
fi

# Google Chrome (GUI ブラウザ - CI ではスキップ)
echo -e "\n${BLUE}[google-chrome]${NC}"
if [[ "${CI:-}" == "true" ]]; then
    echo -e "${YELLOW}Skipping google-chrome (CI environment)${NC}"
elif [[ "$(uname -m)" != "x86_64" ]]; then
    echo -e "${YELLOW}⚠${NC} google-chrome is only supported on x86_64; skipping${NC}"
elif command_exists google-chrome; then
    echo -e "${GREEN}✓${NC} google-chrome is already installed: $(get_version google-chrome)"
    if [[ "$UPDATE_MODE" == true ]]; then
        echo "Updating google-chrome..."
        TMP_DIR=$(mktemp -d)
        curl -fL "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" \
            -o "${TMP_DIR}/google-chrome.deb"
        sudo apt install -y "${TMP_DIR}/google-chrome.deb"
        rm -rf "${TMP_DIR}"
    fi
else
    echo "Installing google-chrome..."
    TMP_DIR=$(mktemp -d)
    curl -fL "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" \
        -o "${TMP_DIR}/google-chrome.deb"
    sudo apt install -y "${TMP_DIR}/google-chrome.deb"
    rm -rf "${TMP_DIR}"
fi

# fastfetch
echo -e "\n${BLUE}[fastfetch]${NC}"
if command_exists fastfetch; then
    echo -e "${GREEN}✓${NC} fastfetch is already installed: $(get_version fastfetch)"
else
    echo "Installing fastfetch..."
    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" ]]; then
        FASTFETCH_ARCH="amd64"
    elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
        FASTFETCH_ARCH="arm64"
    else
        echo -e "${RED}✗${NC} Unsupported architecture: $ARCH"
        exit 1
    fi

    FASTFETCH_VERSION=$(curl -fsSL https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    FASTFETCH_URL="https://github.com/fastfetch-cli/fastfetch/releases/download/${FASTFETCH_VERSION}/fastfetch-linux-${FASTFETCH_ARCH}.deb"

    TMP_DIR=$(mktemp -d)
    curl -fL "$FASTFETCH_URL" -o "${TMP_DIR}/fastfetch.deb"
    sudo dpkg -i "${TMP_DIR}/fastfetch.deb" || sudo apt-get install -f -y
    rm -rf "${TMP_DIR}"
fi

echo -e "\n${GREEN}=== Tool installation complete! ===${NC}"
echo -e "\n${YELLOW}Note:${NC} Make sure ~/.local/bin is in your PATH"
echo -e "You may need to restart your shell or run: source ~/.zshenv"
