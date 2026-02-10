# Repository Guidelines

## Project Structure & Module Organization
- `darwin/`: macOS configuration with its own `flake.nix`, `home-manager/`, and nix-darwin modules.
- `nixos/`: NixOS configuration with its own `flake.nix`, `home-manager/`, and system modules.
- `nixvim/`: Standalone Neovim configuration as a separate flake.
- `scripts/`: Helper utilities for Makefile commands.
- `docs/`: How‑to docs (installation, Nix, pre-commit, VSCode, mise, etc.).
- `vscode/`: Settings and extension sync scripts.

## Architecture Support
- **Apple Silicon (aarch64-darwin)**: Uses nixpkgs unstable + nix-darwin unstable + home-manager unstable.
- **Intel Mac (x86_64-darwin)**: Uses nixpkgs unstable + nix-darwin unstable + home-manager unstable.
- Architecture is auto-detected at build time.

## Build, Test, and Development Commands

### macOS (darwin)
- `make help`: Interactive overview of available tasks.
- `make home-manager-apply`: Update darwin flake, apply user config (`darwin/.#home`).
- `make nix-darwin-apply`: Apply full macOS (nix-darwin) config (`darwin/.#all`).
- `make nix-darwin-check`: Build-check darwin config only (no apply).
- `make nix-check-all`: CI-like sequence: channel update + HM apply + darwin check.
- `make flake-update-darwin`: Update darwin/flake.lock.

### NixOS
- `make nixos-switch`: Apply NixOS system config (`nixos/.#desktop`).
- `make nixos-build`: Build NixOS config without applying.
- `make flake-update-nixos`: Update nixos/flake.lock.

### Nixvim
- `make flake-update-nixvim`: Update nixvim/flake.lock.
- `nix run ./nixvim`: Run standalone Neovim with nixvim config.

### Other
- `make flake-update-all`: Update all flake.lock files (darwin, nixos, nixvim).
- `make pre-commit-init` / `make pre-commit-run`: Install/run hooks locally.
- `make vscode-apply` / `make vscode-save`: Apply or snapshot VSCode settings.
- `make mise-install-all` / `make mise-install-npm-commitizen`: Tool installs.

## Coding Style & Naming Conventions
- Use `.editorconfig` rules: UTF-8, LF, final newline, trim whitespace; 2 spaces for YAML/JS/Lua, 4 spaces default, tabs for `Makefile`.
- Prefer small, self-contained modules under `darwin/home-manager/`, `nixos/home-manager/`, `darwin/`, `nixos/`.
- Nix: keep attributes sorted and options grouped; avoid side effects in modules.
- Shell/YAML: keep lines short and declarative; quote variables.

## Testing Guidelines
- Local validation: `make nix-darwin-check` and/or `make nix-check-all`.
- Hooks: run `make pre-commit-run` before pushing.
- CI: GitHub Actions builds flake targets on PRs; fix failures before merge.

## Commit & Pull Request Guidelines
- Conventional Commits with cz-git emojis (e.g., `feat: ✨ add nix module`, `fix: 🐛 correct service option`).
- Keep subject ≤ 72 chars; meaningful body when changing behavior.
- PRs: describe scope and impact, link issues, include screenshots for UI/editor changes.

## Security & Configuration Tips
- Secrets: never commit tokens; `gitleaks` runs via pre-commit and CI. Adjust `.gitleaks.toml` for allowlists.
- Nix: use `make flake-update-darwin` or `make flake-update-nixos` in feature branches; avoid pin drift in unrelated PRs.
- Each OS has independent flake.lock files, allowing different nixpkgs versions if needed.

## Agent-Specific Notes
- Prefer dry-run/build checks before apply. Touch only relevant modules.
- Update docs in `docs/` when changing workflows or commands.
- Test on the appropriate target (`darwin` vs `nixos`) and keep cross-platform changes isolated.
