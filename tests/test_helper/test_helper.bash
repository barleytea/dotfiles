#!/usr/bin/env bash

# bats test helper functions

# Determine the bats library path
# Try different methods to find bats libraries
BATS_LIB_LOADED=false

# Method 1: Use nativeBuildInputs from Nix (most reliable for nix develop)
if [ -n "${nativeBuildInputs:-}" ] && [ "$BATS_LIB_LOADED" = false ]; then
    for input in $nativeBuildInputs; do
        if [ -d "$input/share/bats/bats-support" ]; then
            load "$input/share/bats/bats-support/load"
            load "$input/share/bats/bats-assert/load"
            load "$input/share/bats/bats-file/load"
            BATS_LIB_LOADED=true
            break
        fi
    done
fi

# Method 2: Check XDG_DATA_DIRS
if [ -n "${XDG_DATA_DIRS:-}" ] && [ "$BATS_LIB_LOADED" = false ]; then
    IFS=: read -ra DIRS <<< "$XDG_DATA_DIRS"
    for dir in "${DIRS[@]}"; do
        if [ -d "$dir/bats/bats-support" ]; then
            load "$dir/bats/bats-support/load"
            load "$dir/bats/bats-assert/load"
            load "$dir/bats/bats-file/load"
            BATS_LIB_LOADED=true
            break
        fi
    done
fi

# Method 3: Try Homebrew
if command -v brew &>/dev/null 2>&1 && [ "$BATS_LIB_LOADED" = false ]; then
    BREW_PREFIX="$(brew --prefix 2>/dev/null)"
    if [ -n "$BREW_PREFIX" ] && [ -d "${BREW_PREFIX}/lib/bats-support" ]; then
        load "${BREW_PREFIX}/lib/bats-support/load"
        load "${BREW_PREFIX}/lib/bats-assert/load"
        load "${BREW_PREFIX}/lib/bats-file/load"
        BATS_LIB_LOADED=true
    fi
fi

# Project root directory
export PROJECT_ROOT="${BATS_TEST_DIRNAME}/../.."

# Setup function for tests
setup_test_env() {
    # Create a temporary directory for test files
    export TEST_TEMP_DIR="$(temp_make)"
    export BATS_TMPDIR="${TEST_TEMP_DIR}"
}

# Teardown function for tests
teardown_test_env() {
    # Clean up temporary directory
    if [ -n "${TEST_TEMP_DIR}" ] && [ -d "${TEST_TEMP_DIR}" ]; then
        temp_del "${TEST_TEMP_DIR}"
    fi
}

# Helper: Run a script from the scripts directory
run_script() {
    local script_name="$1"
    shift
    run "${PROJECT_ROOT}/scripts/${script_name}" "$@"
}

# Helper: Create a mock Makefile for testing
create_mock_makefile() {
    local target_file="${1:-${TEST_TEMP_DIR}/Makefile}"
    cat > "${target_file}" <<'EOF'
test-target: ## This is a test target
	echo "Running test"

another-target: ## Another test target
	echo "Another test"

## Category Header ##
category-task: ## Task in category
	echo "Category task"
EOF
    echo "${target_file}"
}

# Helper: Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Helper: Skip test if command is not available
require_command() {
    local cmd="$1"
    if ! command_exists "${cmd}"; then
        skip "Command '${cmd}' is not available"
    fi
}

# Helper: Mock nix profile path
mock_nix_profile() {
    export NIX_PROFILE="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
    mkdir -p "$(dirname "${NIX_PROFILE}")"
    cat > "${NIX_PROFILE}" <<'EOF'
# Mock Nix profile
export NIX_PATH="nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixpkgs"
EOF
}
