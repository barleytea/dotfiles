# Nix operations

Basic operations are performed using `just`.

- [Nix](#nix)
  - [Apply home-manager settings](#apply-home-manager-settings)
  - [Apply all nix-darwin settings](#apply-all-nix-darwin-settings)
  - [Apply nix-darwin-homebrew settings](#apply-nix-darwin-homebrew-settings)
  - [Apply all nix settings](#apply-all-nix-settings)
  - [Install a new package](#install-a-new-package)
  - [Rollback](#rollback)

## Nix

### Apply home-manager settings

```sh
just home-manager-apply
```

### Apply all nix-darwin settings

```sh
just nix-darwin-apply
```

#### Apply nix-darwin-homebrew settings

```sh
just nix-darwin-homebrew-apply
```

#### Apply nix-darwin-system settings

```sh
just nix-darwin-system-apply
```

#### Apply nix-darwin-service settings

```sh
just nix-darwin-service-apply
```

### Apply all nix settings

```sh
just nix-update-all
```

### Install a new package

```sh
# search package: https://search.nixos.org/packages

# install package
nix profile install nixpkgs#hoge
```

### Upgrade a package

```sh
nix profile upgrade hoge
```

### Rollback

#### 1. Check generations

```sh
nix-env --list-generations
```

```
1   2024-10-17 10:19:29
2   2024-10-17 11:55:16
3   2024-10-17 19:19:37
4   2024-11-06 18:37:37
5   2024-11-06 18:52:58   (current)
```

#### 2. Rollback

```sh
nix-env --rollback

# or

nix-env --switch-generation 3
```

## Special Configuration Handling

### Claude Configuration

While most dotfiles configurations are managed through the Nix store for reproducibility and immutability, the Claude configuration is handled as an exception using direct symbolic links.

**Rationale:**
- Claude Desktop application modifies its configuration files directly during runtime
- The Nix store approach would prevent Claude from updating its own settings
- Direct symbolic links allow bidirectional synchronization between the application and dotfiles

**Implementation:**
The Claude configuration files are linked directly from the dotfiles repository:
```sh
~/.claude/CLAUDE.md → ~/git_repos/github.com/barleytea/dotfiles/home-manager/claude/config/CLAUDE.md
~/.claude/settings.json → ~/git_repos/github.com/barleytea/dotfiles/home-manager/claude/config/settings.json
```

This approach enables:
- Claude to modify its configuration files as needed
- Changes to persist in the dotfiles repository automatically
- Version control of Claude settings through git

**Configuration Location:**
- Dotfiles: `home-manager/claude/default.nix`
- Target directory: `~/.claude/`
