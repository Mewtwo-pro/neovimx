
require ('basic')
--require ('flashx')
require ('linea_flash')
require ('explorer')
require ('autocomplete')
require ('fzf_config')
require ('auto_comando')
require ('buscar')
require ('git_net')
    
return require('packer').startup(function(use)
    use 'wbthomason/packer.nvim'
    use 'hrsh7th/nvim-cmp'
    use 'hrsh7th/cmp-buffer'
    use {
    "ibhagwan/fzf-lua",
    requires = { "nvim-tree/nvim-web-devicons" }
    }
end)

