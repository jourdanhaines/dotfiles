return {
    {
        "echasnovski/mini.files",
        version = false,
        opts = {
            mappings = {
                close = "q",
                go_in = "l",
                go_in_plus = "<CR>",
                go_out = "h",
                go_out_plus = "H",
                synchronize = "=",
            },
        },
        keys = {
            { "<S-Tab>", mode = { "n", "v" }, function() require("mini.files").open(vim.api.nvim_buf_get_name(0), true) end, desc = "Open file explorer (current file)" },
            { "<C-w><C-d>", function() require("mini.files").open(vim.fn.getcwd(), true) end, desc = "Open file explorer (cwd)" },
        },
    }
}
