return {
    "mikavilpas/yazi.nvim",
    version = "*",
    event = "VeryLazy",
    dependencies = {
        { "nvim-lua/plenary.nvim", lazy = true },
    },
    keys = {
        {
            "<S-Tab>",
            mode = { "n", "v" },
            "<cmd>Yazi<cr>",
            desc = "Open yazi at the current file",
        },
        {
            "<C-w><C-d>",
            "<cmd>Yazi cwd<cr>",
            desc = "Open the file manager in nvim's working directory",
        },
    },
    opts = {
        open_for_directories = true,
        keymaps = {
            show_help = "<f1>",
            open_file_in_vertical_split = "<c-|>",
            open_file_in_horizontal_split = "<c-->",
            open_file_in_tab = "<C-t>",
            grep_in_directory = "<C-s>",
            cycle_open_buffers = "<Tab>",
            copy_relative_path_to_selected_files = "<C-y>",
            open_and_pick_window = "<C-o>",
        },
        integrations = {
            grep_in_directory = function(directory)
                require("fzf-lua").live_grep({ cwd = directory })
            end,
        },
    },
    init = function()   
        -- mark netrw as loaded so it's not loaded at all.
        --
        -- More details: https://github.com/mikavilpas/yazi.nvim/issues/802
        vim.g.loaded_netrwPlugin = 1
    end,
}
