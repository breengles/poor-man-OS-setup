-- File explorer using mini.files
return {
  'echasnovski/mini.files',
  version = '*',
  keys = {
    {
      '<leader>e',
      function()
        local MiniFiles = require 'mini.files'
        if not MiniFiles.close() then
          MiniFiles.open(vim.api.nvim_buf_get_name(0))
        end
      end,
      desc = 'Toggle file explorer',
    },
  },
  opts = {
    mappings = {
      go_in_plus = '<CR>',
    },
  },
}
