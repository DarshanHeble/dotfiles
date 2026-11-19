return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
      cmdline = {
        enabled = true,
        view = "cmdline_popup", -- floating input field
        format = {
          cmdline = { icon = "", hl_group = "DiagnosticSignInfo" },
          search_down = { icon = " ", hl_group = "DiagnosticSignInfo" },
          search_up = { icon = " ", hl_group = "DiagnosticSignInfo" },
          filter = { icon = "$", hl_group = "DiagnosticSignInfo" },
          lua = { icon = "", hl_group = "DiagnosticSignInfo" },
          help = { icon = "", hl_group = "DiagnosticSignInfo" },
        },
      },
      views = {
        cmdline_popup = {
          position = {
            row = "15%", -- floating at the top
            col = "50%",
          },
          size = {
            width = 60,
            height = "auto",
          },
          border = {
            style = "rounded",
            padding = { 0, 1 },
          },
          win_options = {
            winhighlight = {
              Normal = "NormalFloat",
              FloatBorder = "FloatBorder",
            },
          },
        },
      },
      routes = {
        {
          filter = {
            event = "msg_show",
            any = {
              { find = "%d+L, %d+B" },
              { find = "; after #%d+" },
              { find = "; before #%d+" },
            },
          },
          opts = { skip = true },
        },
      },
      messages = {
        enabled = true,
      },
      popupmenu = {
        enabled = true,
      },
    },
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- test new blink
  -- { import = "nvchad.blink.lazyspec" },

  -- {
  -- 	"nvim-treesitter/nvim-treesitter",
  -- 	opts = {
  -- 		ensure_installed = {
  -- 			"vim", "lua", "vimdoc",
  --      "html", "css"
  -- 		},
  -- 	},
  -- },
}
