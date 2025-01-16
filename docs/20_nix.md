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
