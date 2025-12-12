-- Custom colorscheme plugin
return {
  'mycolorscheme', -- name doesn't matter for local plugins
  name = 'mycolorscheme',
  lazy = false,
  priority = 1000, -- Load before other plugins
  dir = vim.fn.stdpath 'config' .. '/lua/custom/plugins', -- point to this directory
  config = function()
    -- Define the colorscheme setup function
    local function setup()
      vim.cmd 'hi clear'
      if vim.fn.exists 'syntax_on' then
        vim.cmd 'syntax reset'
      end
      vim.o.background = 'dark'
      vim.o.termguicolors = true
      vim.g.colors_name = 'mycolorscheme'

      local hi = function(group, opts)
        vim.api.nvim_set_hl(0, group, opts)
      end

      -- Base colors
      hi('Normal', { fg = '#dadada', bg = '#1f1f1f' })

      -- Teal/cyan group (#3cb9ab)
      hi('DiffText', { fg = '#3cb9ab' })
      hi('ErrorMsg', { fg = '#3cb9ab' })
      hi('WarningMsg', { fg = '#3cb9ab' })
      hi('PreProc', { fg = '#3cb9ab' })
      hi('Exception', { fg = '#3cb9ab' })
      hi('Error', { fg = '#3cb9ab' })
      hi('DiffDelete', { fg = '#3cb9ab' })
      hi('GitGutterDelete', { fg = '#3cb9ab' })
      hi('GitGutterChangeDelete', { fg = '#3cb9ab' })
      hi('cssIdentifier', { fg = '#3cb9ab' })
      hi('cssImportant', { fg = '#3cb9ab' })
      hi('Type', { fg = '#3cb9ab' })
      hi('Identifier', { fg = '#3cb9ab' })

      -- Blue group (#3a7cce)
      hi('PMenuSel', { fg = '#3a7cce' })
      hi('Constant', { fg = '#3a7cce' })
      hi('Repeat', { fg = '#3a7cce' })
      hi('DiffAdd', { fg = '#3a7cce' })
      hi('GitGutterAdd', { fg = '#3a7cce' })
      hi('cssIncludeKeyword', { fg = '#3a7cce' })
      hi('Keyword', { fg = '#3a7cce' })

      -- Light blue group (#81c6f6)
      hi('IncSearch', { fg = '#81c6f6' })
      hi('Title', { fg = '#81c6f6' })
      hi('PreCondit', { fg = '#81c6f6' })
      hi('Debug', { fg = '#81c6f6' })
      hi('SpecialChar', { fg = '#81c6f6' })
      hi('Conditional', { fg = '#81c6f6' })
      hi('Todo', { fg = '#81c6f6' })
      hi('Special', { fg = '#81c6f6' })
      hi('Label', { fg = '#81c6f6' })
      hi('Delimiter', { fg = '#81c6f6' })
      hi('Number', { fg = '#81c6f6' })
      hi('CursorLineNR', { fg = '#81c6f6' })
      hi('Define', { fg = '#81c6f6' })
      hi('MoreMsg', { fg = '#81c6f6' })
      hi('Tag', { fg = '#81c6f6' })
      hi('String', { fg = '#81c6f6' })
      hi('MatchParen', { fg = '#81c6f6' })
      hi('Macro', { fg = '#81c6f6' })
      hi('DiffChange', { fg = '#81c6f6' })
      hi('GitGutterChange', { fg = '#81c6f6' })
      hi('cssColor', { fg = '#81c6f6' })

      -- Yellow group (#dad491)
      hi('Function', { fg = '#dad491' })

      -- Purple/magenta group (#b984b9)
      hi('Directory', { fg = '#b984b9' })
      hi('markdownLinkText', { fg = '#b984b9' })
      hi('javaScriptBoolean', { fg = '#b984b9' })
      hi('Include', { fg = '#b984b9' })
      hi('Storage', { fg = '#b984b9' })
      hi('cssClassName', { fg = '#b984b9' })
      hi('cssClassNameDot', { fg = '#b984b9' })

      -- Cyan group (#6de5ff)
      hi('Statement', { fg = '#6de5ff' })
      hi('Operator', { fg = '#6de5ff' })
      hi('cssAttr', { fg = '#6de5ff' })

      -- UI elements
      hi('Pmenu', { fg = '#dadada', bg = '#454545' })
      hi('SignColumn', { bg = '#1f1f1f' })
      hi('Title', { fg = '#dadada' })
      hi('LineNr', { fg = '#747474', bg = '#1f1f1f' })
      hi('NonText', { fg = '#c481ff', bg = '#1f1f1f' })
      hi('Comment', { fg = '#c481ff', italic = true })
      hi('SpecialComment', { fg = '#c481ff', italic = true })
      hi('CursorLine', { bg = '#454545' })
      hi('TabLineFill', { bg = '#454545' })
      hi('TabLine', { fg = '#747474', bg = '#454545' })
      hi('StatusLine', { fg = '#dadada', bg = '#454545', bold = true })
      hi('StatusLineNC', { fg = '#dadada', bg = '#1f1f1f' })
      hi('Search', { fg = '#dadada', bg = '#c481ff' })
      hi('VertSplit', { fg = '#454545' })
      hi('Visual', { bg = '#454545' })
    end

    -- Register the colorscheme
    setup()

    -- Create a command to reload the colorscheme
    vim.api.nvim_create_user_command('MyColorscheme', setup, {})
  end,
}
