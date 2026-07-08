{ pkgs, lib, ... }: let
  settingsJson = pkgs.writeText "zed-settings.json" (builtins.toJSON {
    theme = {
      mode = "dark";
      dark = "Dracula";
      light = "One Light";
    };
    buffer_font_family = "Hack Nerd Font Mono";
    buffer_font_size = 14;
    ui_font_size = 14;

    tab_size = 2;
    vim_mode = true;
    relative_line_numbers = true;
    format_on_save = "on";
    autosave = { after_delay = { milliseconds = 1000; }; };
    soft_wrap = "editor_width";

    scrollbar.show = "never";
    indent_guides = {
      enabled = true;
      line_width = 1;
      active_line_width = 2;
      coloring = "indent_aware";
    };
    inlay_hints = {
      enabled = true;
      show_type_hints = true;
      show_parameter_hints = true;
      show_other_hints = true;
    };

    git = {
      inline_blame = {
        enabled = true;
        delay_ms = 600;
      };
      git_gutter = "tracked_files";
    };

    terminal = {
      font_family = "Hack Nerd Font Mono";
      font_size = 14;
      shell = "system";
    };

    languages = {
      Go = {
        tab_size = 4;
        formatter = "language_server";
        language_servers = [ "gopls" ];
      };
      Nix = {
        tab_size = 2;
        formatter = "language_server";
        language_servers = [ "nil" ];
      };
      Lua = {
        tab_size = 2;
        formatter = "language_server";
        language_servers = [ "lua-language-server" ];
      };
      TypeScript = {
        tab_size = 2;
        formatter = "prettier";
        language_servers = [ "typescript-language-server" "...rest" ];
      };
      JavaScript = {
        tab_size = 2;
        formatter = "prettier";
        language_servers = [ "typescript-language-server" "...rest" ];
      };
      Python = {
        tab_size = 4;
        formatter = "language_server";
        language_servers = [ "pyright" ];
      };
    };
  });

  keymapJson = pkgs.writeText "zed-keymap.json" (builtins.toJSON [
    {
      context = "VimControl && !menu";
      bindings = {
        "ctrl-h" = [ "workspace::ActivatePaneInDirection" "Left" ];
        "ctrl-l" = [ "workspace::ActivatePaneInDirection" "Right" ];
        "ctrl-k" = [ "workspace::ActivatePaneInDirection" "Up" ];
        "ctrl-j" = [ "workspace::ActivatePaneInDirection" "Down" ];
      };
    }
    {
      context = "Editor && vim_mode == normal && !menu";
      bindings = {
        "g d" = "editor::GoToDefinition";
        "g D" = "editor::GoToDeclaration";
        "g r" = "editor::FindAllReferences";
        "g i" = "editor::GoToImplementation";
        "g t" = "editor::GoToTypeDefinition";
        "K" = "editor::Hover";
        "space e" = "diagnostics::Deploy";
        "space f" = "file_finder::Toggle";
        "space s" = "outline::Toggle";
        "space S" = "project_symbols::Toggle";
        "space /" = "workspace::NewSearch";
        "space r" = "editor::Rename";
        "[ d" = "editor::GoToDiagnostic";
        "] d" = "editor::GoToDiagnostic";
        "space a" = "editor::ToggleCodeActions";
      };
    }
    {
      context = "Editor && !menu";
      bindings = {
        "ctrl-/" = "editor::ToggleComments";
      };
    }
  ]);
in {
  # zed 本体は OS ごとのパッケージマネージャ（Homebrew cask / nixpkgs）で管理。
  # 設定ファイルを実ファイルとして配置し、Zed からの書き換えを可能にする。
  home.activation.writeZedConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$HOME/.config/zed"
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 600 '${settingsJson}' "$HOME/.config/zed/settings.json"
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 600 '${keymapJson}' "$HOME/.config/zed/keymap.json"
  '';
}
