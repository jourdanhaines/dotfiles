-- Global keymaps (always available)
vim.keymap.set("v", "<A-Up>", ":m '<-2<CR>gv=gv")
vim.keymap.set("v", "<A-Down>", ":m '>+1<CR>gv=gv")

-- Line navigation (replaces ^ and $)
vim.keymap.set("n", "<leader><Left>", "^", { desc = "Go to first character of line" })
vim.keymap.set("n", "<leader><Right>", "$", { desc = "Go to last character of line" })

-- Center cursor after jumps
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Page down and center" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Page up and center" })
vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result centered" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Prev search result centered" })

-- Better paste (don't yank replaced text)
vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste without yanking" })

-- Delete without yanking
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete without yanking" })

-- Quick save
vim.keymap.set("n", "<leader>w", "<cmd>w<cr>", { desc = "Save file" })

-- Select all
vim.keymap.set("n", "<leader>sa", "ggVG", { desc = "Select all" })

-- Buffer navigation
vim.keymap.set("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })
vim.keymap.set("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
vim.keymap.set("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })
vim.keymap.set("n", "<leader>bo", "<cmd>%bd|e#|bd#<cr>", { desc = "Close other buffers" })

-- Clear search highlights
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear highlights" })

local harpoon = require("harpoon")

vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end)
vim.keymap.set("n", "<leader>rm", function() harpoon:list():remove() end)
vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)

vim.keymap.set("n", "<C-1>", function() harpoon:list().select(1) end)
vim.keymap.set("n", "<C-2>", function() harpoon:list().select(2) end)
vim.keymap.set("n", "<C-3>", function() harpoon:list().select(3) end)
vim.keymap.set("n", "<C-4>", function() harpoon:list().select(4) end)

vim.keymap.set("n", "<C-P>", function() harpoon:list():prev() end)
vim.keymap.set("n", "<C-N>", function() harpoon:list():next() end)

-- Open fzf for current directory
vim.keymap.set("n", "ff", function()
    require("fzf-lua").files({
        cwd = vim.fn.getcwd(),
        git_icons = true,
        file_icons = true
    })
end, { desc = "Project Files" })

-- Open live grep
vim.keymap.set("n", "<C-F>", function()
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

        -- Code actions
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Code action" }))

        -- Diagnostics
        vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic" })
        vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
        vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
        vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostics to loclist" })

        -- Signature help
        vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, opts)
    end,
})

local telescope = require("telescope.builtin")
vim.keymap.set("n", "<leader>pf", telescope.find_files, {})
vim.keymap.set("n", "<C-p>", telescope.git_files, {})
