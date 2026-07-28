require("nvim-treesitter.configs").setup({
  ensure_installed = {
    "c", "cpp", "lua", "python", "javascript"
  },

  auto_install = true,

  highlight = {
    enable = true,                 -- 🔴 ESTO ES CLAVE
    additional_vim_regex_highlighting = false,
  },
})
