return {
    -- add gruvbox
    {
        "mycolorscheme.vim",
        name="mycolorscheme_plg",
        dir="colors/mycolorscheme.vim",
        dev=true,
    },

    -- Configure LazyVim to load gruvbox
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "mycolorscheme",
        },
    }
}
