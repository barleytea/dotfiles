#!/bin/bash

set -euo pipefail

# =============================================================================
# difit-auto-detect.sh
# Automatically detects git state and opens appropriate diff view
# with difit in a cmux browser split pane.
#
# Dependencies:
# - cmux https://cmux.app/
# - difit https://github.com/yoshiko-pg/difit
#
# Setup:
# 1. Install cmux
# Download from https://cmux.app/ and move to /Applications/
# 1.1 Change "Socket Control Mode" to "Automation Mode"
#
# 2. Install difit
# npm install -g difit
#
# 3. Make this script executable and place it somewhere on your PATH
# chmod +x difit-auto-detect.sh
# mv difit-auto-detect.sh /usr/local/bin/difit-cmux
#
# 4. (Optional) Bind to a global shortcut via your preferred launcher
# e.g. Alfred, Karabiner Elements, Raycast, etc.
#
# Usage:
# Run this script while cmux is focused on a git repository pane.
# The script will:
# - Detect the current branch and default branch
# - Show diff against merge-base (for feature branches)
# - Show diff against HEAD (for default branch or detached HEAD)
# - Open the result in a cmux browser split at http://localhost:4966/
# - Automatically shut down the difit server when the browser pane is closed
# =============================================================================

CMUX="/Applications/cmux.app/Contents/Resources/bin/cmux"
DIFIT_PORT="${DIFIT_PORT:-4966}"

extract_json_value() {
    local json="$1"
    local key="$2"

    printf '%s\n' "$json" |
        sed -nE "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"([^\"]+)\".*/\1/p" |
        head -n1
}

extract_kv_value() {
    local body="$1"
    local key="$2"

    printf '%s\n' "$body" | awk -F= -v search_key="$key" '$1 == search_key {print substr($0, length($1) + 2)}' | head -n1
}

resolve_git_root() {
    local dir="$1"

    [[ -n "$dir" ]] || return 1
    [[ "$dir" != "unknown" ]] || return 1
    [[ -d "$dir" ]] || return 1

    git -C "$dir" rev-parse --show-toplevel 2>/dev/null
}

# Get the working directory of the currently focused cmux pane.
# Recent cmux builds support --json, but keep the legacy parser as fallback.
sidebarStateJson=$("$CMUX" --json sidebar-state 2>/dev/null || true)
sidebarStateText=$("$CMUX" sidebar-state 2>/dev/null || true)

targetDir=""

for candidate in \
    "$(extract_json_value "$sidebarStateJson" "focused_cwd")" \
    "$(extract_json_value "$sidebarStateJson" "cwd")" \
    "$(extract_kv_value "$sidebarStateText" "focused_cwd")" \
    "$(extract_kv_value "$sidebarStateText" "cwd")" \
    "$PWD"
do
    if gitRoot=$(resolve_git_root "$candidate"); then
        targetDir="$gitRoot"
        break
    fi
done

if [[ -z "$targetDir" ]]; then
    echo "Error: Could not detect a git repository from cmux sidebar-state or \$PWD" >&2
    if [[ -n "$sidebarStateText" ]]; then
        echo "cmux sidebar-state:" >&2
        echo "$sidebarStateText" >&2
    fi
    "$CMUX" notify --title "Difit" --body "No git repository detected from cmux pane"
    exit 1
fi

cd "$targetDir"

# Provide immediate feedback so the user knows the script is running
"$CMUX" notify --title "Difit" --body "Loading diff: $targetDir"

echo "🔍 Detecting git state..."

currentBranch=$(git rev-parse --abbrev-ref HEAD)

# Detect default branch (origin/HEAD → origin/main → origin/master)
defaultBranch=$(git symbolic-ref refs/remotes/origin/HEAD --short 2>/dev/null)

if [[ -z "$defaultBranch" ]]; then
    if git rev-parse --verify origin/main >/dev/null 2>&1; then
        defaultBranch="origin/main"
    elif git rev-parse --verify origin/master >/dev/null 2>&1; then
        defaultBranch="origin/master"
    fi
fi

# Kill any process using the difit port
kill_difit() {
    local pids
    pids=$(lsof -ti:"$DIFIT_PORT" 2>/dev/null || true)
    [[ -n "$pids" ]] && echo "$pids" | xargs kill 2>/dev/null || true
}

trap kill_difit EXIT INT TERM

difitArgs=(--mode unified --no-open --clean --include-untracked --port "$DIFIT_PORT")

echo "🚀 Starting difit server..."

if [[ -z "$defaultBranch" ]] || [[ "$currentBranch" == "${defaultBranch#origin/}" ]]; then
    # On the default branch or no remote — diff working directory against HEAD
    difit working "${difitArgs[@]}" &
else
    mergeBase=$(git merge-base HEAD "$defaultBranch" 2>/dev/null)
    if [[ -z "$mergeBase" ]]; then
        # Fallback if merge-base cannot be determined
        difit working "${difitArgs[@]}" &
    else
        echo "🔀 Branch: $currentBranch (base: ${defaultBranch#origin/})"
        difit "$mergeBase" . "${difitArgs[@]}" &
    fi
fi

# Wait until the difit server is ready (timeout: 30s)
_difit_wait_timeout=30
_difit_waited=0
until curl -s "http://localhost:${DIFIT_PORT}/" > /dev/null 2>&1; do
    sleep 0.5
    _difit_waited=$(( _difit_waited + 1 ))
    if (( _difit_waited >= _difit_wait_timeout * 2 )); then
        echo "Error: difit server did not start within ${_difit_wait_timeout}s" >&2
        exit 1
    fi
done

# Open in a cmux browser split and get the surface ID
browserSurface=$("$CMUX" --json browser open-split "http://localhost:${DIFIT_PORT}/" | grep -o '"ref" *: *"surface:[^"]*"' | head -1 | grep -o 'surface:[0-9]*')

if [[ -z "$browserSurface" ]]; then
    echo "Warning: Could not get browser surface ID, difit server running in background" >&2
    wait
    exit 0
fi

# Wait until the browser pane is closed, then shut down the server (timeout: 8h)
_browser_watch_timeout=$(( 8 * 3600 ))
_browser_watched=0
while "$CMUX" surface-health 2>&1 | grep -q "$browserSurface"; do
    sleep 1
    _browser_watched=$(( _browser_watched + 1 ))
    if (( _browser_watched >= _browser_watch_timeout )); then
        echo "Warning: browser watch timed out after 8h, shutting down difit" >&2
        break
    fi
done

kill_difit
