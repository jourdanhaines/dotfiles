return {
    'nvim-telescope/telescope.nvim', tag = '*',
    dependencies = {
        'nvim-lua/plenary.nvim',
        'nvim-tree/nvim-web-devicons',
        { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    }
}
