vim.g.gruvbox_material_background = "medium"
vim.cmd.colorscheme("gruvbox-material")
vim.opt.termguicolors = true

vim.cmd([[
  highlight Normal guibg=NONE ctermbg=NONE
  highlight NormalNC guibg=NONE ctermbg=NONE
  highlight SignColumn guibg=NONE ctermbg=NONE
  highlight EndOfBuffer guibg=NONE ctermbg=NONE
]])
require ('basic')
require ('linea_flash')
require ('explorer')
--require ('autocomplete')
require ('auto_comando')
require ('buscar')
require ('git_net')
require ('task')    
require ('ia_browser')    
require ('telescop')    
require ('termMode')    

return require('packer').startup(function(use)
    use {
  "sainnhe/gruvbox-material"
}
    use 'wbthomason/packer.nvim'
    use 'hrsh7th/nvim-cmp'
    use 'hrsh7th/cmp-buffer'
use {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    requires = {
        { "nvim-lua/plenary.nvim" },
    }
}
     
end)

