# cmux Guide

cmux is a macOS terminal multiplexer built on top of Ghostty.
https://cmux.app/

## Installation

cmux is managed via Homebrew in the nix-darwin configuration:

```nix
# darwin/default.nix (homebrew.casks)
"cmux"
```

After applying:
```bash
make nix-darwin-apply
```

## Initial Setup

### Enable Automation Mode

cmux needs to be in Automation Mode for scripting support:

1. Open cmux
2. Go to **Settings → Socket Control Mode**
3. Switch to **Automation Mode**

This enables the `cmux` CLI binary at:
`/Applications/cmux.app/Contents/Resources/bin/cmux`

## Appearance (shared with Ghostty)

cmux is built on Ghostty and reads the same config file:
`~/.config/ghostty/config`

Current settings applied automatically:
- **Theme**: Dracula
- **Font**: Hack Nerd Font
- **Background opacity**: 0.65
- **Background blur**: 20

To change appearance, edit the ghostty config:
```bash
$EDITOR ~/.config/ghostty/config
# or edit source: darwin/home-manager/ghostty/config/
```

## difit-cmux Command

The `difit-cmux` command opens a git diff view using [difit](https://github.com/yoshiko-pg/difit)
in a cmux browser split pane.

### Prerequisites

```bash
# Install difit globally (managed via mise/npm)
npm install -g difit
```

### Usage

Run from any pane in cmux focused on a git repository:

```bash
difit-cmux
```

The script will:
1. Detect the git root from the focused cmux pane's working directory
2. Determine the appropriate diff target:
   - **Feature branch**: diff against merge-base with default branch
   - **Default branch / detached HEAD**: diff working directory against HEAD
3. Start the difit server and open a browser split in cmux
4. Automatically shut down the difit server when the browser pane is closed

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DIFIT_PORT` | `4966` | Port for the difit HTTP server |

```bash
# Use a custom port
DIFIT_PORT=5000 difit-cmux
```

### Script Location

Deployed by Home Manager to `~/.local/bin/difit-cmux` from:
`darwin/home-manager/scripts/difit-auto-detect.sh`

Managed via `darwin/home-manager/cmux/default.nix`.

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+F` | Launch difit-cmux from any zsh prompt (zle widget) |

The `Ctrl+F` binding is registered as a zle widget in zsh:

```zsh
# darwin/home-manager/shell/zsh/config/functions.zsh
function difit_cmux_widget() {
  if [[ -x "/Applications/cmux.app/Contents/Resources/bin/cmux" ]]; then
    "${HOME}/.local/bin/difit-cmux" &>/dev/null &
    disown
  else
    zle -M "difit-cmux: cmux not found"
    return 1
  fi
  zle reset-prompt
}
```

The widget launches difit-cmux in the background so the shell prompt is not blocked.

### Claude Code Stop Hook

difit-cmux is automatically triggered when a Claude Code session ends:

- **Hook script**: `~/.local/bin/difit-cmux-hook` (deployed from `darwin/home-manager/scripts/difit-cmux-hook.sh`)
- **Registered in**: `darwin/home-manager/claude/config/settings.json` under `hooks.Stop`

The hook only runs when:
1. cmux is installed and running (`pgrep -x "cmux"` succeeds)
2. The session `cwd` is inside a git repository
3. `jq` is available on `$PATH`

This gives automatic diff review after every Claude Code session with zero manual effort.

### Binding to a Global Shortcut (Optional)

You can also bind `difit-cmux` to a keyboard shortcut via:
- **Raycast**: Create a Script Command pointing to `~/.local/bin/difit-cmux`
- **Alfred**: Create a workflow action
- **Karabiner Elements**: Map a key to run the script

## Development Flow with difit-cmux

### When to Use difit

| Timing | Action | Trigger |
|--------|--------|---------|
| During coding | Spot-check current diff | `Ctrl+F` |
| After Claude Code session | Automatic diff review | Stop hook (auto) |
| Before commit | Review staged + unstaged diff | `Ctrl+F` → stage → commit |
| Before PR creation | Full branch diff vs merge-base | `Ctrl+F` on feature branch |

### Complete Branch-to-PR Flow

```
# 1. Create a new branch
git checkout -b feat/my-feature

# 2. Code with Claude Code
claude

# 3. difit auto-launches after session ends (Stop hook)
#    Or press Ctrl+F at any time to review diff

# 4. Stage changes and generate commit message
git add -p
# Then use /generate-commit-msg skill:
# /generate-commit-msg

# 5. Commit
git commit

# 6. Before PR: press Ctrl+F to review full branch diff
#    (difit-cmux auto-detects merge-base diff for feature branches)

# 7. Create PR
gh pr create
```

### Integration with /generate-commit-msg

After reviewing the diff with `Ctrl+F`:

1. Stage your changes: `git add -p`
2. Run `/generate-commit-msg` in Claude Code
3. Claude analyzes `git diff --staged` and proposes a gitmoji commit message
4. Edit and commit

## cmux-workspace Command

The `cmux-workspace` command provides a simple branch-based workspace switcher for cmux.
It replaces the kra ticket-driven workflow with a minimal branch = workspace model.

### Usage

Run from any directory inside a git repository:

```bash
# Open branch picker and create/switch to a cmux workspace
cmux-workspace

# Also launch Claude Code in the new workspace
cmux-workspace --claude
```

### Features

- **fzf branch picker**: Lists local branches, remote branches, and existing worktrees
- **New branch creation**: Select `[新規ブランチを作成]` to create a new branch + worktree
- **git worktree management**: Uses `gwq` to create/reuse worktrees automatically
- **cmux workspace**: Opens the worktree directory in a new cmux workspace
- **Auto-rename**: Renames the workspace to `<repo>/<branch>` for easy identification
- **Claude Code integration**: Pass `--claude` to auto-start Claude Code in the new workspace

### Gitignored Files

When creating a new worktree, environment files (`.env`, `node_modules`, etc.) are NOT
automatically copied. Set these up manually or use your project's bootstrap script.

### Script Location

Deployed by Home Manager to `~/.local/bin/cmux-workspace` from:
`darwin/home-manager/scripts/cmux-workspace.sh`

Managed via `darwin/home-manager/cmux/default.nix`.

### Comparison with Zellij Worktree

| Feature | cmux-workspace | zellij-worktree |
|---------|---------------|-----------------|
| Terminal | cmux (Ghostty) | Zellij |
| Workspace unit | branch | worktree (tab/session) |
| Ticket management | None (branch-only) | None |
| Claude Code | `--claude` flag | Manual |

## Troubleshooting

### "No git repository detected"

The script falls back to `$PWD` if cmux sidebar-state cannot determine the focused pane.
Ensure you are running from within a git repository.

### difit server fails to start within 30s

The script times out after 30 seconds waiting for the difit server.
Check that `difit` is installed and on `$PATH`:

```bash
which difit
difit --version
```

### Port already in use

If port 4966 is in use by a previous run:

```bash
lsof -ti:4966 | xargs kill
# or use a different port:
DIFIT_PORT=5000 difit-cmux
```

### cmux binary not found

Verify cmux is installed and Automation Mode is enabled:

```bash
ls /Applications/cmux.app/Contents/Resources/bin/cmux
```
