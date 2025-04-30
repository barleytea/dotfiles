return {
  "folke/noice.nvim",
  event = "VeryLazy",
  dependencies = {
    "MunifTanjim/nui.nvim",
    "rcarriga/nvim-notify",
  },
  opts = {
    lsp = {
      -- オーバーライド
      override = {
        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
        ["vim.lsp.util.stylize_markdown"] = true,
        ["cmp.entry.get_documentation"] = true,
      },
      hover = {
        enabled = true,
      },
      signature = {
        enabled = true,
      },
    },
    cmdline = {
      enabled = true,
      view = "cmdline_popup", -- cmdline_popup or cmdline
      opts = {}, -- cmdlineのオプション
      format = {
        -- コマンドラインの表示設定
        cmdline = { pattern = "^:", icon = ":", lang = "vim" },
        search_down = { kind = "search", pattern = "^/", icon = " ", lang = "regex" },
        search_up = { kind = "search", pattern = "^%?", icon = " ", lang = "regex" },
        filter = { pattern = "^:%s*!", icon = "$", lang = "bash" },
        lua = { pattern = { "^:%s*lua%s+", "^:%s*lua%s*=%s*", "^:%s*=%s*" }, icon = "", lang = "lua" },
        help = { pattern = "^:%s*he?l?p?%s+", icon = "󰋖 " },
        input = {}, -- ユーザー入力の設定
      },
    },
    messages = {
      -- メッセージ/通知/コマンドの表示設定
      enabled = true,
      view = "notify", -- notifyかmini
      view_error = "notify", -- エラーメッセージのビュー
      view_warn = "notify", -- 警告メッセージのビュー
      view_history = "messages", -- :messagesのビュー
      view_search = "virtualtext", -- 検索結果のビュー
    },
    popupmenu = {
      enabled = true, -- コマンドラインのポップアップメニューを有効化
      backend = "nui", -- nvimのネイティブメニューまたはnui
      kind_icons = {}, -- シンボルアイコン
    },
    redirect = {
      view = "popup",
      filter = { event = "msg_show" },
    },
    commands = {
      history = {
        -- :Noice historyのオプション
        view = "split",
        opts = { enter = true, format = "details" },
        filter = {
          any = {
            { event = "notify" },
            { error = true },
            { warning = true },
            { event = "msg_show", kind = { "" } },
            { event = "lsp", kind = "message" },
          },
        },
      },
      -- :Noice last
      last = {
        view = "popup",
        opts = { enter = true, format = "details" },
        filter = {
          any = {
            { event = "notify" },
            { error = true },
            { warning = true },
            { event = "msg_show", kind = { "" } },
            { event = "lsp", kind = "message" },
          },
        },
        filter_opts = { count = 1 },
      },
      -- :Noice errors
      errors = {
        view = "popup",
        opts = { enter = true, format = "details" },
        filter = { error = true },
        filter_opts = { reverse = true },
      },
    },
    notify = {
      -- ノーティフィケーションをnoice.nvimにルーティング
      enabled = true,
      view = "notify",
    },
    health = {
      checker = true, -- ヘルスチェッカーを有効化
    },
    smart_move = {
      -- 入力中にポップアップ位置をインテリジェントに移動
      enabled = true,
      excluded_filetypes = { "cmp_menu", "cmp_docs", "notify" },
    },
    presets = {
      -- デフォルトのプリセット
      bottom_search = true, -- 画面下部に検索UI (デフォルトは上部)
      command_palette = true, -- コマンドパレット代替
      long_message_to_split = true, -- 長いメッセージをsplitに送信
      inc_rename = true, -- インクリメンタルリネームのUI
      lsp_doc_border = false, -- LSPのhoverドキュメント周囲のボーダーを追加
    },
    views = {
      cmdline_popup = {
        position = {
          row = "50%",
          col = "50%",
        },
        size = {
          width = 60,
          height = "auto",
        },
        border = {
          style = "rounded",
        },
      },
      popupmenu = {
        relative = "editor",
        position = {
          row = 8,
          col = "50%",
        },
        size = {
          width = 60,
          height = 10,
        },
        border = {
          style = "rounded",
          padding = { 0, 1 },
        },
        win_options = {
          winhighlight = { Normal = "Normal", FloatBorder = "DiagnosticInfo" },
        },
      },
    },
  },
  -- キーマップの例
  keys = {
    { "<S-Enter>", function() require("noice").redirect(vim.fn.getcmdline()) end, mode = "c", desc = "コマンド出力をリダイレクト" },
    { "<leader>nl", function() require("noice").cmd("last") end, desc = "Noice 最後のメッセージ" },
    { "<leader>nh", function() require("noice").cmd("history") end, desc = "Noice 履歴" },
    { "<leader>na", function() require("noice").cmd("all") end, desc = "Noice すべて" },
    { "<leader>nd", function() require("noice").cmd("dismiss") end, desc = "Noice 消去" },
    { "<c-f>", function() if not require("noice.lsp").scroll(4) then return "<c-f>" end end, silent = true, expr = true, desc = "スクロールダウン", mode = {"i", "n", "s"} },
    { "<c-b>", function() if not require("noice.lsp").scroll(-4) then return "<c-b>" end end, silent = true, expr = true, desc = "スクロールアップ", mode = {"i", "n", "s"} },
  },
}
