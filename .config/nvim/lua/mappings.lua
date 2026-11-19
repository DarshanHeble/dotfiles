require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- Project and Dashboard shortcuts
map("n", "<leader>fp", "<cmd>Telescope find_files cwd=~/Projects<cr>", { desc = "Find file in Projects" })
map("n", "<leader>db", "<cmd>NvDash<cr>", { desc = "Open Dashboard" })
