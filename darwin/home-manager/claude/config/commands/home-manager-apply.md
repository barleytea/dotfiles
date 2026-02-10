---
name: home-manager-apply
description: Apply home-manager configuration changes
usage: /user:home-manager-apply
---

# Home Manager Apply Command

Apply home-manager configuration changes to update your system environment.

## Usage
- `/user:home-manager-apply` - Apply home-manager configuration

## Pre-apply checks
Before applying home-manager changes, run these checks:

```bash
# Check git status for uncommitted changes
git status

# Check for syntax errors in configuration
nix-instantiate --parse ~/git_repos/github.com/barleytea/dotfiles/home-manager/default.nix
```

## Application process
1. Navigate to dotfiles directory
2. Run home-manager apply via make command
3. Review any warnings or errors
4. Verify changes took effect

## Common commands
```bash
# Apply configuration
make home-manager-apply
```
