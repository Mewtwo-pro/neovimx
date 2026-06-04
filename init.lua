
require ('basic')
require ('flashx')
require ('linea_flash')
require ('explorer')
require ('autocomplete')
require ('fzf_config')
require ('auto_comando')
require ('buscar')
    
return require('packer').startup(function(use)
    use 'wbthomason/packer.nvim'

    use 'hrsh7th/nvim-cmp'
    use 'hrsh7th/cmp-buffer'
    use {
    "ibhagwan/fzf-lua",
    requires = { "nvim-tree/nvim-web-devicons" }
    }
    use({
    "folke/flash.nvim",
    config = function()
      require("flash").setup({
	mappings = false, -- Desactiva mapeos globales
      modes = {
        char = {
          enabled = false, -- Esto evita que 't', 'f', etc. activen flash
        },
      },
    })
  end,
})    
end)

