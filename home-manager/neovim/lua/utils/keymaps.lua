-- キーマップユーティリティ関数

-- グローバル変数の検査によりVSCode環境かを判定する関数
local function is_vscode()
  return vim.g.vscode == 1
end

-- キーマップ設定のヘルパー関数
local function map(mode, lhs, rhs, opts)
  -- デフォルトのオプション設定
  local options = { noremap = true, silent = true }

  -- 追加オプションがあれば上書き
  if opts then
    options = vim.tbl_extend("force", options, opts)
  end

  -- キーマップを設定
  vim.keymap.set(mode, lhs, rhs, options)
end

-- VSCode環境とNeovim環境の両方で機能するキーマップ設定
local function map_universal(mode, lhs, rhs_nvim, rhs_vscode, opts)
  if is_vscode() then
    -- VSCode環境用のマッピング
    if type(rhs_vscode) == "string" and rhs_vscode:match("^<Cmd>call VSCodeNotify") then
      -- すでにVSCodeNotify形式の場合はそのまま使用
      map(mode, lhs, rhs_vscode, opts)
    else
      -- VSCodeNotify形式に変換
      local vscode_command = string.format('<Cmd>call VSCodeNotify("%s")<CR>', rhs_vscode)
      map(mode, lhs, vscode_command, opts)
    end
  else
    -- Neovim環境用のマッピング
    map(mode, lhs, rhs_nvim, opts)
  end
end

-- VSCode環境でのみ機能するキーマップ設定
local function map_vscode(mode, lhs, rhs, opts)
  if is_vscode() then
    if type(rhs) == "string" and rhs:match("^<Cmd>call VSCodeNotify") then
      -- すでにVSCodeNotify形式の場合はそのまま使用
      map(mode, lhs, rhs, opts)
    else
      -- VSCodeNotify形式に変換
      local vscode_command = string.format('<Cmd>call VSCodeNotify("%s")<CR>', rhs)
      map(mode, lhs, vscode_command, opts)
    end
  end
end

-- Neovim環境でのみ機能するキーマップ設定
local function map_neovim(mode, lhs, rhs, opts)
  if not is_vscode() then
    map(mode, lhs, rhs, opts)
  end
end

-- 条件付きキーマップのヘルパー関数
local function map_with_condition(condition, mode, lhs, rhs, opts)
  if condition then
    map(mode, lhs, rhs, opts)
  end
end

-- キーマップをリセットする関数
local function unmap(mode, lhs)
  pcall(function() vim.keymap.del(mode, lhs) end)
end

-- キーマップをリストアップする関数
local function list_maps(mode)
  local maps = vim.api.nvim_get_keymap(mode)
  local result = {}

  for _, map in ipairs(maps) do
    table.insert(result, {
      mode = map.mode,
      lhs = map.lhs,
      rhs = map.rhs or "",
      noremap = map.noremap
    })
  end

  return result
end

-- キーマップの競合をチェックする関数
local function check_conflicts(maps1, maps2)
  local conflicts = {}

  for _, map1 in ipairs(maps1) do
    for _, map2 in ipairs(maps2) do
      if map1.mode == map2.mode and map1.lhs == map2.lhs and map1.rhs ~= map2.rhs then
        table.insert(conflicts, {
          mode = map1.mode,
          lhs = map1.lhs,
          rhs1 = map1.rhs,
          rhs2 = map2.rhs
        })
      end
    end
  end

  return conflicts
end

-- モジュールをエクスポート
return {
  map = map,
  map_universal = map_universal,
  map_vscode = map_vscode,
  map_neovim = map_neovim,
  map_with_condition = map_with_condition,
  unmap = unmap,
  list_maps = list_maps,
  check_conflicts = check_conflicts,
  is_vscode = is_vscode
}
