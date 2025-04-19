# VSCode settings

## Apply VSCode settings

```sh
just vscode-apply
```

## Save VSCode settings

```sh
just vscode-save
```

## VSCode-Neovim Synchronization

### Synchronize VSCode and Neovim settings

```sh
just vscode-sync
```

This command automatically synchronizes settings between VSCode and Neovim. The following settings are mainly synchronized:

- Key bindings
- Editor appearance (font, theme, etc.)
- Basic editing behavior (tab size, word wrap, etc.)

### Setup Neovim initialization file for VSCode

```sh
just vscode-neovim-init
```

This command generates the initialization file needed to use Neovim from VSCode.
It configures the necessary settings to make Neovim mode function correctly within VSCode.
