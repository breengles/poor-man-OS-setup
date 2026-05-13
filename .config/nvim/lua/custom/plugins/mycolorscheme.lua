-- Custom colorscheme plugin with dark and light variants
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
      vim.o.termguicolors = true
      vim.g.colors_name = 'mycolorscheme'

      local hi = function(group, opts)
        vim.api.nvim_set_hl(0, group, opts)
      end

      local is_dark = vim.o.background == 'dark'

      -- Palette
      local bg = is_dark and '#1f1f1f' or '#fafaf8'
      local fg = is_dark and '#dadada' or '#333333'
      local ui_bg = is_dark and '#454545' or '#e4e4e4'
      local line_nr = is_dark and '#747474' or '#999999'
      local comment = is_dark and '#c481ff' or '#8e55c0'
      local non_text = is_dark and '#c481ff' or '#a66de0'

      local teal = is_dark and '#3cb9ab' or '#0d7d6c'
      local blue = is_dark and '#3a7cce' or '#2b5fad'
      local light_blue = is_dark and '#81c6f6' or '#2878b7'
      local yellow = is_dark and '#dad491' or '#7a6b0a'
      local purple = is_dark and '#b984b9' or '#8a4f8a'
      local cyan = is_dark and '#6de5ff' or '#0b7e8e'

      local search_bg = is_dark and '#c481ff' or '#d4b5f0'
      local visual_bg = is_dark and '#454545' or '#ccd5e0'
      local cursor_line_bg = is_dark and '#454545' or '#eaeaea'

      -- Base colors
      hi('Normal', { fg = fg, bg = bg })

      -- Teal group
      hi('DiffText', { fg = teal })
      hi('ErrorMsg', { fg = teal })
      hi('WarningMsg', { fg = teal })
      hi('PreProc', { fg = teal })
      hi('Exception', { fg = teal })
      hi('Error', { fg = teal })
      hi('DiffDelete', { fg = teal })
      hi('GitGutterDelete', { fg = teal })
      hi('GitGutterChangeDelete', { fg = teal })
      hi('cssIdentifier', { fg = teal })
      hi('cssImportant', { fg = teal })
      hi('Type', { fg = teal })
      hi('Identifier', { fg = teal })

      -- Blue group
      hi('PMenuSel', { fg = blue })
      hi('Constant', { fg = blue })
      hi('Repeat', { fg = blue })
      hi('DiffAdd', { fg = blue })
      hi('GitGutterAdd', { fg = blue })
      hi('cssIncludeKeyword', { fg = blue })
      hi('Keyword', { fg = blue })

      -- Light blue group
      hi('IncSearch', { fg = light_blue })
      hi('PreCondit', { fg = light_blue })
      hi('Debug', { fg = light_blue })
      hi('SpecialChar', { fg = light_blue })
      hi('Conditional', { fg = light_blue })
      hi('Todo', { fg = light_blue })
      hi('Special', { fg = light_blue })
      hi('Label', { fg = light_blue })
      hi('Delimiter', { fg = light_blue })
      hi('Number', { fg = light_blue })
      hi('CursorLineNR', { fg = light_blue })
      hi('Define', { fg = light_blue })
      hi('MoreMsg', { fg = light_blue })
      hi('Tag', { fg = light_blue })
      hi('String', { fg = light_blue })
      hi('MatchParen', { fg = light_blue })
      hi('Macro', { fg = light_blue })
      hi('DiffChange', { fg = light_blue })
      hi('GitGutterChange', { fg = light_blue })
      hi('cssColor', { fg = light_blue })

      -- Yellow group
      hi('Function', { fg = yellow })

      -- Purple/magenta group
      hi('Directory', { fg = purple })
      hi('markdownLinkText', { fg = purple })
      hi('javaScriptBoolean', { fg = purple })
      hi('Include', { fg = purple })
      hi('Storage', { fg = purple })
      hi('cssClassName', { fg = purple })
      hi('cssClassNameDot', { fg = purple })

      -- Cyan group
      hi('Statement', { fg = cyan })
      hi('Operator', { fg = cyan })
      hi('cssAttr', { fg = cyan })

      -- UI elements
      hi('Pmenu', { fg = fg, bg = ui_bg })
      hi('SignColumn', { bg = bg })
      hi('Title', { fg = fg })
      hi('LineNr', { fg = line_nr, bg = bg })
      hi('NonText', { fg = non_text, bg = bg })
      hi('Comment', { fg = comment, italic = true })
      hi('SpecialComment', { fg = comment, italic = true })
      hi('CursorLine', { bg = cursor_line_bg })
      hi('TabLineFill', { bg = ui_bg })
      hi('TabLine', { fg = line_nr, bg = ui_bg })
      hi('StatusLine', { fg = fg, bg = ui_bg, bold = true })
      hi('StatusLineNC', { fg = fg, bg = bg })
      hi('Search', { fg = fg, bg = search_bg })
      hi('VertSplit', { fg = ui_bg })
      hi('Visual', { bg = visual_bg })
    end

    -- Register the colorscheme
    setup()



    -- Create a command to reload the colorscheme
    vim.api.nvim_create_user_command('MyColorscheme', setup, {})
  end,
}
