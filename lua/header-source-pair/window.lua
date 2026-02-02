local M = {}

local recent = require("header-source-pair.recent")

local function get_windows()
  local windows = vim.api.nvim_tabpage_list_wins(0)
  local normal_windows = {}

  for _, win in ipairs(windows) do
    local config = vim.api.nvim_win_get_config(win)
    if config.relative == "" then
      table.insert(normal_windows, win)
    end
  end

  return normal_windows
end

function M.open_pair(header_path, source_path)
  -- Record pair in recent history
  recent.add_pair(header_path, source_path)

  local windows = get_windows()

  if #windows >= 2 then
    vim.api.nvim_set_current_win(windows[1])
    vim.cmd("edit " .. vim.fn.fnameescape(header_path))

    vim.api.nvim_set_current_win(windows[2])
    vim.cmd("edit " .. vim.fn.fnameescape(source_path))
  else
    vim.cmd("edit " .. vim.fn.fnameescape(header_path))
    vim.cmd("vsplit " .. vim.fn.fnameescape(source_path))
  end
end

function M.open_single(filepath)
  vim.cmd("edit " .. vim.fn.fnameescape(filepath))
end

return M
