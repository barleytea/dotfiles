local wezterm = require("wezterm")
require("handler")

----------------------------------------------------
-- Base
----------------------------------------------------

base_config = {
  automatically_reload_config = true,
  font_size = 12.0,
  use_ime = true,
  window_background_opacity = 0.6,
  macos_window_background_blur = 20,
}

----------------------------------------------------
-- Tab
----------------------------------------------------

tab_config = {
  window_decorations = "RESIZE",
  show_tabs_in_tab_bar = true,
  window_frame = {
    inactive_titlebar_bg = "none",
    active_titlebar_bg = "none",
  },
  window_background_gradient = {
    colors = { "#000000" },
  },
  show_new_tab_button_in_tab_bar = false,
  -- show_close_tab_button_in_tabs = false,
}

----------------------------------------------------
-- Color
----------------------------------------------------

color_config = {
  color_scheme = "Dracula",
  colors = {
    tab_bar = {
      inactive_tab_edge = "none",
    },
  }
}

----------------------------------------------------
-- Keybinds
----------------------------------------------------

keybinds = {
  disable_default_key_bindings = true,
  keys = require("keybinds").keys,
  key_tables = require("keybinds").key_tables,
  leader = { key = "b", mods = "CTRL", timeout_milliseconds = 2000 },
}

----------------------------------------------------
-- Build Config
----------------------------------------------------

config_tmp = {
  base_config,
  tab_config,
  color_config,
  keybinds,
}

config = {}
for _, block in ipairs(config_tmp) do
  for key, value in pairs(block) do
    config[key] = value
  end
end

return config
