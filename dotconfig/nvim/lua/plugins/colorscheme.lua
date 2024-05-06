return {
    -- add gruvbox
    { "mycolorscheme.vim" },

    -- Configure LazyVim to load gruvbox
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "mycolorscheme",
        },
    }
}
