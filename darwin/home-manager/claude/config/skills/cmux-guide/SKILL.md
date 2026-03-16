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

### Binding to a Global Shortcut (Optional)

You can bind `difit-cmux` to a keyboard shortcut via:
- **Raycast**: Create a Script Command pointing to `~/.local/bin/difit-cmux`
- **Alfred**: Create a workflow action
- **Karabiner Elements**: Map a key to run the script

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
