local M = {}

local recent = require("header-source-pair.recent")

-- Default config (overridden by init.lua)
M.config = {
  split = "vertical",
  header_percent = 50,
}

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

local function apply_split_size()
  local percent = M.config.header_percent or 50
  if M.config.split == "horizontal" then
    local total_height = vim.o.lines
    local header_height = math.floor(total_height * percent / 100)
    vim.cmd("resize " .. header_height)
  else
    local total_width = vim.o.columns
    local header_width = math.floor(total_width * percent / 100)
    vim.cmd("vertical resize " .. header_width)
  end
end

function M.open_pair(header_path, source_path)
  -- Record pair in recent history
  recent.add_pair(header_path, source_path)

  local windows = get_windows()
  local split_cmd = M.config.split == "horizontal" and "split" or "vsplit"

  if #windows >= 2 then
    vim.api.nvim_set_current_win(windows[1])
    vim.cmd("edit " .. vim.fn.fnameescape(header_path))

    vim.api.nvim_set_current_win(windows[2])
    vim.cmd("edit " .. vim.fn.fnameescape(source_path))
  else
    vim.cmd("edit " .. vim.fn.fnameescape(header_path))
    vim.cmd(split_cmd .. " " .. vim.fn.fnameescape(source_path))
    -- Move back to header window and apply size
    vim.cmd("wincmd p")
    apply_split_size()
    -- Move back to source window
    vim.cmd("wincmd p")
  end
end

function M.open_single(filepath)
  vim.cmd("edit " .. vim.fn.fnameescape(filepath))
end

return M
