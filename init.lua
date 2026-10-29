vim.o.background = "light"
vim.cmd("colorscheme default")
require ('basic')
require ('linea_flash')
require ('explorer')
require ('auto_comando')
require ('buscar')
require ('git_net')
require ('lspx')    
require ('task')    
require ('ia_browser')    
require ('minipick')
require ('xterm')
-- plugins
return require('packer').startup(function(use)
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
use({
  "projekt0n/github-nvim-theme",
  as = "github-theme",
  config = function()
    require("github-theme").setup({})
    vim.cmd([[colorscheme github_light]])
  end,
})
use 'wbthomason/packer.nvim'
use 'neovim/nvim-lspconfig'
use {
  'williamboman/mason.nvim'
}
use 'williamboman/mason-lspconfig.nvim'

use {
  "SmiteshP/nvim-navic",
  requires = "neovim/nvim-lspconfig"
}
end)
