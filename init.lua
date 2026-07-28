vim.g.gruvbox_material_background = "medium"
vim.cmd.colorscheme("gruvbox-material")
vim.opt.termguicolors = true

require ('basic')
require ('linea_flash')
require ('explorer')
require ('auto_comando')
require ('buscar')
require ('git_net')
require ('task')    
require ('ia_browser')    
require ('termMode')    
require ('treesiterx')
require ('minipick')
require ('xterm')
return require('packer').startup(function(use)
    use {
  "sainnhe/gruvbox-material"
}
use 'nvim-lua/plenary.nvim'
use({
  "echasnovski/mini.pick",
  branch = "main",
  config = function()
    require("mini.pick").setup({
  options = {
    use_cache = true,
  },
  mappings = {},
})
  end,
})
use{
  "nvim-treesitter/nvim-treesitter",
  branch = "master",
  lazy = false,
}
use 'wbthomason/packer.nvim'
end)

