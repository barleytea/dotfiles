# nixvim-config

Personal Neovim configuration using [nixvim](https://github.com/nix-community/nixvim).

## Features

- **Standalone nixvim configuration** - Works independently without dotfiles
- **Cross-platform** - Supports macOS (both Intel and Apple Silicon), Linux, and NixOS
- **LSP support** - Pre-configured language servers (Lua, Nix, etc.)
- **Modern UI** - Telescope, Neo-tree, Lualine, and more
- **Git integration** - Gitsigns, Neogit, and Diffview
- **VSCode integration** - VSCode-Neovim keybindings

## Usage

### Standalone (temporary)

Run Neovim with this config directly:

```bash
nix run github:barleytea/nixvim-config
```

### Install to user profile

Install permanently to your Nix profile:

```bash
nix profile install github:barleytea/nixvim-config
```

After installation, `nvim`, `vi`, `vim`, and `vimdiff` commands will be available.

### Use with home-manager

Add to your `flake.nix`:

```nix
{
  inputs = {
    nixvim-config.url = "github:barleytea/nixvim-config";
  };

  outputs = { self, nixpkgs, home-manager, nixvim-config, ... }: {
    homeConfigurations.yourname = home-manager.lib.homeManagerConfiguration {
      modules = [
        nixvim-config.homeManagerModules.default
        # ... your other modules
      ];
    };
  };
}
```

### Use with NixOS

Add to your system configuration:

```nix
{
  inputs.nixvim-config.url = "github:barleytea/nixvim-config";

  outputs = { self, nixpkgs, nixvim-config, ... }: {
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
      modules = [{
        environment.systemPackages = [
          nixvim-config.packages.${system}.default
        ];
      }];
    };
  };
}
```

## Configuration Structure

```
config/
├── default.nix        # Main entry point
├── options.nix        # Neovim basic options
├── keymaps.nix        # Key mappings
├── colorschemes.nix   # Color schemes (Dracula with transparency)
├── vscode.nix         # VSCode integration
└── plugins/
    ├── lsp.nix        # LSP configuration (nil_ls, lua_ls, etc.)
    ├── completion.nix # Completion (nvim-cmp, copilot, etc.)
    ├── ui.nix         # UI plugins (telescope, neo-tree, lualine, etc.)
    ├── editor.nix     # Editor plugins (treesitter, surround, comment, etc.)
    └── git.nix        # Git integration (gitsigns, neogit, diffview)
```

## Key Bindings

- **Leader key**: `<Space>`
- **Local leader**: `,`

### Basic

- `jj` - Exit insert mode
- `<leader>w` - Save file
- `<Esc>` - Clear search highlights

### Window Navigation

- `<C-h/j/k/l>` - Navigate between windows

### Buffer Navigation

- `<S-h>` - Previous buffer
- `<S-l>` - Next buffer

### Telescope

- `<leader>ff` - Find files
- `<leader>fg` - Live grep
- `<leader>fb` - Buffers
- `<leader>fh` - Help tags

### LSP

- `gd` - Go to definition
- `gr` - Go to references
- `K` - Hover documentation
- `<leader>ca` - Code actions
- `<leader>rn` - Rename symbol

### Git

- `<leader>gg` - Open Neogit
- `<leader>gd` - Diffview open
- `<leader>gh` - Diffview file history
- `]c` / `[c` - Next/previous git hunk

## Requirements

- Nix with flakes enabled
- nixpkgs unstable (this configuration requires unstable)

## License

MIT
