return {
  "zbirenbaum/copilot-cmp",
  dependencies = {
    "zbirenbaum/copilot.lua",
    "hrsh7th/nvim-cmp",
  },
  config = function()
    require("copilot_cmp").setup()

    -- Get the existing cmp config
    local cmp = require("cmp")
    local config = cmp.get_config()

    -- Add copilot to the sources if it's not already there
    if config.sources then
      table.insert(config.sources, { name = "copilot" })
      cmp.setup(config)
    end
  end,
}
