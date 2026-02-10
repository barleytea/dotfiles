local wezterm = require("wezterm")
local status_bar = require "status-bar"
local util = require "util.util"
local mux = wezterm.mux
local SOLID_LEFT_TRIANGLE = wezterm.nerdfonts.ple_lower_right_triangle
local SOLID_RIGHT_TRIANGLE = wezterm.nerdfonts.ple_upper_left_triangle
local RIGHT_ARROW = wezterm.nerdfonts.pl_right_hard_divider


----------------------------------------------------
-- Set the size of the window
----------------------------------------------------
wezterm.on('gui-startup', function(cmd)
  local tab, pane, window = mux.spawn_window(cmd or {})
  window:gui_window():toggle_fullscreen()
end)

----------------------------------------------------
-- Format tabs
----------------------------------------------------

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local background = "#5c6d74"
  local foreground = "#FFFFFF"
  local edge_background = "none"
  if tab.is_active then
    background = "#ae8b2d"
    foreground = "#FFFFFF"
  end
  local edge_foreground = background

  local pane = tab.active_pane
  local title = util.basename(pane.foreground_process_name)

  local cwd_uri = pane.current_working_dir
  if cwd_uri then
      local path = cwd_uri.file_path
      local _, _, last_segment = string.find(path, "/([^/]+)/?$")
      if last_segment then
          title = last_segment
      end
  end
  title = "   " .. wezterm.truncate_right(title, max_width - 1) .. "   "
  return {
    { Background = { Color = edge_background } },
    { Foreground = { Color = edge_foreground } },
    { Text = SOLID_LEFT_TRIANGLE },
    { Background = { Color = background } },
    { Foreground = { Color = foreground } },
    { Text = title },
    { Background = { Color = edge_background } },
    { Foreground = { Color = edge_foreground } },
    { Text = SOLID_RIGHT_TRIANGLE },
  }
end)

----------------------------------------------------
-- Update Right Status
----------------------------------------------------

wezterm.on('update-right-status', function(window, pane)
  local cwd = util.get_cwd(pane)
  cells = status_bar.update_status_bar(cwd)

  local colors = {
      "#6f00e6",
      "#6200d4",
      "#5e00c0",
      "#5000b0",
      "#4c009a",
      "#450080",
      "#3f0066",
      "#36004c",
      "#2e0032",
      "#26001e",
  }

  local elements = {}
  local text_fg = "#c0c0c0"
  local num_cells = 0

  function push(text, is_last)
      local cell_no = num_cells + 1
      table.insert(elements, { Foreground = { Color = text_fg } })
      table.insert(elements, { Background = { Color = colors[cell_no] } })
      table.insert(elements, { Text = ' ' .. text .. ' ' })
    if not is_last then
      table.insert(elements, { Foreground = { Color = colors[cell_no + 1] } })
      table.insert(elements, { Text = RIGHT_ARROW })
    end
    num_cells = num_cells + 1
  end

  while #cells > 0 do
      local cell = table.remove(cells, 1)
      push(cell, #cells == 0)
  end

  window:set_right_status(wezterm.format(elements))
end)
