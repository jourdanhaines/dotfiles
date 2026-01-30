vim.g.mapleader = " "

vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.o.softtabstop = 4

vim.o.number = true
vim.o.relativenumber = true

vim.o.wrap = false

vim.o.hlsearch = false
vim.o.incsearch = true

vim.o.scrolloff = 8

vim.o.updatetime = 50

vim.o.colorcolumn = "120"

vim.o.autochdir = true

vim.diagnostic.config({
    virtual_text = true,
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
})

require("config.lazy")

-- Post-init packages
local harpoon = require("harpoon")
harpoon:setup({
    settings = {
        save_on_toggle = true,
        sync_on_ui_close = true,
        key = function()
            return vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("\n", "")
        end,
    }
})

require("config.keymaps")

