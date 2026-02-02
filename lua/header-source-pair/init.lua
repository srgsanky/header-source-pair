local finder = require("header-source-pair.finder")
local window = require("header-source-pair.window")

local M = {}

M.config = {
  header_extensions = { "h", "hpp", "hxx", "hh", "H" },
  source_extensions = { "c", "cpp", "cc", "cxx", "C" },
}

function M.setup(opts)
  opts = opts or {}

  if opts.header_extensions then
    M.config.header_extensions = opts.header_extensions
    finder.header_extensions = opts.header_extensions
  end

  if opts.source_extensions then
    M.config.source_extensions = opts.source_extensions
    finder.source_extensions = opts.source_extensions
  end

  vim.api.nvim_create_user_command("HeaderSourcePair", function()
    M.open_pair()
  end, { desc = "Open header/source pair in split view" })
end

function M.open_pair(filepath)
  filepath = filepath or vim.api.nvim_buf_get_name(0)

  if filepath == "" then
    vim.notify("No file in current buffer", vim.log.levels.WARN)
    return
  end

  local file_type = finder.get_file_type(filepath)
  if not file_type then
    vim.notify("Current file is not a C/C++ header or source file", vim.log.levels.WARN)
    return
  end

  local pair_path = finder.find_pair(filepath)

  if not pair_path then
    vim.notify("No matching " .. (file_type == "header" and "source" or "header") .. " file found", vim.log.levels.INFO)
    window.open_single(filepath)
    return
  end

  local header_path, source_path
  if file_type == "header" then
    header_path = vim.fn.fnamemodify(filepath, ":p")
    source_path = pair_path
  else
    header_path = pair_path
    source_path = vim.fn.fnamemodify(filepath, ":p")
  end

  window.open_pair(header_path, source_path)
end

return M
