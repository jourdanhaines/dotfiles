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

vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function()
        vim.highlight.on_yank({ timeout = 150 })
        local lines = #vim.v.event.regcontents
        if lines > 1 then
            vim.schedule(function()
                vim.notify(lines .. " lines yanked", vim.log.levels.INFO)
            end)
        end
    end,
})

vim.diagnostic.config({
    virtual_text = true,
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
})

require("config.lazy")

require("config.keymaps")

