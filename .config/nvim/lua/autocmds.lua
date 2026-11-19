require "nvchad.autocmds"

-- Open NvimTree instead of the dashboard when a directory is passed (e.g. `nvim .` or `nvim <dir>`)
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function(data)
    local directory = vim.fn.isdirectory(data.file) == 1
    if directory then
      vim.schedule(function()
        if vim.g.nvdash_displayed then
          require("nvchad.tabufline").close_buffer(vim.g.nvdash_buf)
        end
        require("nvim-tree.api").tree.open()
      end)
    end
  end,
})
