local function get_git_root()
    return vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("\n", "")
end

return {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = {
        "nvim-lua/plenary.nvim"
    },
    config = function()
        local harpoon = require("harpoon")
        harpoon:setup({
            settings = {
                save_on_toggle = true,
                sync_on_ui_close = true,
                key = get_git_root,
            },
            default = {
                create_list_item = function(config, name)
                    local git_root = get_git_root()
                    local file_path = name or vim.api.nvim_buf_get_name(0)
                    if git_root ~= "" and file_path:find(git_root, 1, true) == 1 then
                        file_path = file_path:sub(#git_root + 2)
                    end
                    return {
                        value = file_path,
                        context = {
                            row = vim.api.nvim_win_get_cursor(0)[1],
                            col = vim.api.nvim_win_get_cursor(0)[2],
                        },
                    }
                end,
                select = function(list_item, list, options)
                    local git_root = get_git_root()
                    local full_path = git_root ~= "" and (git_root .. "/" .. list_item.value) or list_item.value
                    vim.cmd("edit " .. vim.fn.fnameescape(full_path))
                    if list_item.context then
                        vim.api.nvim_win_set_cursor(0, { list_item.context.row or 1, list_item.context.col or 0 })
                    end
                end,
            },
        })
    end,
}
