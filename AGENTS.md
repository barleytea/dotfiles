# Repository Guidelines

## Project Structure & Module Organization
- `flake.nix`/`flake.lock`: Nix flake entry; defines `home`, `darwin`, and `nixos` configs.
- `home-manager/`: User-level configs (git, shell, editors, tools).
  - `compat/`: Version-specific packages and settings (unstable vs 24.11).
- `darwin/`, `nixos/`: System-level modules per platform.
  - `darwin/compat/`: Version-specific darwin options (unstable vs 24.11).
- `shared/`: Reusable Nix fragments; `scripts/`: helper utilities.
- `docs/`: How‑to docs (installation, Nix, pre-commit, VSCode, mise, etc.).
- `vscode/`: Settings and extension sync scripts.

## Architecture Support
- **Apple Silicon (aarch64-darwin)**: Uses nixpkgs unstable + nix-darwin unstable + home-manager unstable.
- **Intel Mac (x86_64-darwin)**: Uses nixpkgs 24.11 + nix-darwin 24.11 + home-manager 24.11 (due to compatibility issues with unstable on older macOS).
- Architecture is auto-detected at build time; version-specific settings are isolated in `compat/` directories.

## Build, Test, and Development Commands
- `make help`: Interactive overview of available tasks.
- `make home-manager-apply`: Update flake, apply user config (`.#home`).
- `make nix-darwin-apply`: Apply full macOS (nix-darwin) config (`.#all`).
- `make nix-darwin-check`: Build-check darwin config only (no apply).
- `make nix-check-all`: CI-like sequence: channel update + HM apply + darwin check.
- `make pre-commit-init` / `make pre-commit-run`: Install/run hooks locally.
- `make vscode-apply` / `make vscode-save`: Apply or snapshot VSCode settings.
- `make mise-install-all` / `make mise-install-npm-commitizen`: Tool installs.

## Coding Style & Naming Conventions
- Use `.editorconfig` rules: UTF-8, LF, final newline, trim whitespace; 2 spaces for YAML/JS/Lua, 4 spaces default, tabs for `Makefile`.
- Prefer small, self-contained modules under `home-manager/`, `darwin/`, `nixos/`.
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
- Nix: use `nix flake update` in feature branches; avoid pin drift in unrelated PRs.

## Agent-Specific Notes
- Prefer dry-run/build checks before apply. Touch only relevant modules.
- Update docs in `docs/` when changing workflows or commands.
- Test on the appropriate target (`darwin` vs `nixos`) and keep cross-platform changes isolated.
