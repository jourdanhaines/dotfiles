return {
    "nvim-lualine/lualine.nvim",
    config = function()
        local function get_git_root()
            if vim.b.lualine_git_root ~= nil then
                return vim.b.lualine_git_root
            end

            local dir = vim.fn.expand('%:p:h')
            local git_root = vim.fn.systemlist('git -C ' .. vim.fn.shellescape(dir) .. ' rev-parse --show-toplevel 2>/dev/null')[1]

            if vim.v.shell_error == 0 and git_root then
                vim.b.lualine_git_root = git_root
            else
                vim.b.lualine_git_root = ''
            end

            return vim.b.lualine_git_root
        end

        local function relative_path()
            local filepath = vim.fn.expand('%:p')
            if filepath == '' then
                return '[No Name]'
            end

            local git_root = get_git_root()
            if git_root ~= '' and vim.startswith(filepath, git_root) then
                return filepath:sub(#git_root + 2)
            end

            return vim.fn.expand('%:t')
        end

        require("lualine").setup({
            options = {
                theme = "dracula"
            },
            sections = {
                lualine_c = { relative_path }
            }
        })
    end
}
