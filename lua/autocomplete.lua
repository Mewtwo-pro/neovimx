-- ======================================================
--  CMP (autocompletado)
-- ======================================================

local cmp = require("cmp")

cmp.setup({

  mapping = cmp.mapping.preset.insert({
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
    ["<C-Space>"] = cmp.mapping.complete()
  }),

  sources = {
    { name = "buffer",    max_item_count = 5 },
    { name = "path",      max_item_count = 5 },
  },
})
