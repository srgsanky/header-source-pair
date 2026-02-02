local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
  error("This extension requires telescope.nvim")
end

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local hsp_finder = require("header-source-pair.finder")
local hsp_window = require("header-source-pair.window")

local function get_all_cpp_files()
  local root = hsp_finder.get_project_root()
  local all_extensions = {}

  for _, ext in ipairs(hsp_finder.header_extensions) do
    table.insert(all_extensions, ext)
  end
  for _, ext in ipairs(hsp_finder.source_extensions) do
    table.insert(all_extensions, ext)
  end

  local files = {}
  for _, ext in ipairs(all_extensions) do
    local cmd = string.format("find %s -name '*.%s' -type f 2>/dev/null", vim.fn.shellescape(root), ext)
    local results = vim.fn.systemlist(cmd)
    if vim.v.shell_error == 0 then
      for _, file in ipairs(results) do
        if file and file ~= "" then
          table.insert(files, file)
        end
      end
    end
  end

  return files
end

local function header_source_pair(opts)
  opts = opts or {}

  pickers.new(opts, {
    prompt_title = "Header/Source Pair",
    finder = finders.new_table({
      results = get_all_cpp_files(),
      entry_maker = function(entry)
        local relative = vim.fn.fnamemodify(entry, ":.")
        return {
          value = entry,
          display = relative,
          ordinal = relative,
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          local filepath = selection.value
          local file_type = hsp_finder.get_file_type(filepath)

          if not file_type then
            vim.notify("Selected file is not a C/C++ header or source file", vim.log.levels.WARN)
            return
          end

          local pair_path = hsp_finder.find_pair(filepath)

          if not pair_path then
            vim.notify("No matching " .. (file_type == "header" and "source" or "header") .. " file found", vim.log.levels.INFO)
            hsp_window.open_single(filepath)
            return
          end

          local header_path, source_path
          if file_type == "header" then
            header_path = filepath
            source_path = pair_path
          else
            header_path = pair_path
            source_path = filepath
          end

          hsp_window.open_pair(header_path, source_path)
        end
      end)
      return true
    end,
  }):find()
end

return telescope.register_extension({
  exports = {
    header_source_pair = header_source_pair,
  },
})
