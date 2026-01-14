-- Global keymaps (always available)

vim.g.mapleader = "<Space>"

-- Open fzf for current directory
vim.keymap.set("n", "ff", function()
    require("fzf-lua").files({
        cwd = vim.fn.getcwd(),
        git_icons = true,
        file_icons = true
    })
end, { desc = "Project Files" })

-- Open live grep
vim.keymap.set("n", "fg", function()
    require("fzf-lua").live_grep()
end, { desc = "Live Grep" })

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspKeymaps", { clear = true }),
    callback = function(ev)
        local opts = { buffer = ev.buf, silent = true, noremap = true }

        -- Go to definition
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Go to definition" }))

        -- Hover intellisense
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)

        -- Rename
        vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, opts)

        -- Format
        vim.keymap.set("n", "<space>f", function()
            vim.lsp.buf.format { async = true }
        end, opts)

        -- (optional, nice to have)
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, vim.tbl_extend("force", opts, { desc = "Go to declaration" }))
        vim.keymap.set("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "References" }))
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, vim.tbl_extend("force", opts, { desc = "Implementation" }))
        vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, vim.tbl_extend("force", opts, { desc = "Type definition" }))
    end,
})

