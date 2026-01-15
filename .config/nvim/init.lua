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

require("config.lazy")
require("config.keymaps")
