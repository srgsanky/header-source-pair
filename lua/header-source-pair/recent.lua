local M = {}

local finder = require("header-source-pair.finder")

M.max_entries = 100

local function get_storage_dir()
  local data_dir = vim.fn.stdpath("data")
  local root = finder.get_project_root()
  -- Hash the project root for a safe folder name
  local hash = vim.fn.sha256(root):sub(1, 16)
  return data_dir .. "/header-source-pair/" .. hash
end

local function get_storage_path()
  return get_storage_dir() .. "/recent.json"
end

local function ensure_storage_dir()
  local dir = get_storage_dir()
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end
end

function M.get_pairs()
  local path = get_storage_path()
  if vim.fn.filereadable(path) == 0 then
    return {}
  end

  local file = io.open(path, "r")
  if not file then
    return {}
  end

  local content = file:read("*a")
  file:close()

  if content == "" then
    return {}
  end

  local ok, pairs = pcall(vim.fn.json_decode, content)
  if not ok then
    return {}
  end

  return pairs or {}
end

function M.add_pair(header_path, source_path)
  ensure_storage_dir()

  local pairs = M.get_pairs()

  -- Remove existing entry for this pair if present
  for i, pair in ipairs(pairs) do
    if pair.header == header_path and pair.source == source_path then
      table.remove(pairs, i)
      break
    end
  end

  -- Add new entry at the beginning
  table.insert(pairs, 1, {
    header = header_path,
    source = source_path,
    timestamp = os.time(),
  })

  -- Trim to max entries
  while #pairs > M.max_entries do
    table.remove(pairs)
  end

  -- Write back
  local path = get_storage_path()
  local file = io.open(path, "w")
  if file then
    file:write(vim.fn.json_encode(pairs))
    file:close()
  end
end

return M
