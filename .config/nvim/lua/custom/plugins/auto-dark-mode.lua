-- Auto-switch between dark and light mode based on system appearance.
-- Only loads on macOS or Linux with a display server (desktop).
-- On headless SSH, Neovim's built-in OSC 11 query detects the terminal background at startup.
return {
  'f-person/auto-dark-mode.nvim',
  cond = function()
    return vim.fn.has('mac') == 1 or vim.env.DISPLAY ~= nil or vim.env.WAYLAND_DISPLAY ~= nil
  end,
  opts = {
    update_interval = 1000,
    set_dark_mode = function()
      vim.o.background = 'dark'
    end,
    set_light_mode = function()
      vim.o.background = 'light'
    end,
  },
}
