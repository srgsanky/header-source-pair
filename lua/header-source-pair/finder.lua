local M = {}

M.header_extensions = { "h", "hpp", "hxx", "hh", "H" }
M.source_extensions = { "c", "cpp", "cc", "cxx", "C" }

local function get_extension(filepath)
  return filepath:match("%.([^%.]+)$")
end

local function get_basename(filepath)
  local filename = filepath:match("([^/]+)$")
  if not filename then
    return nil
  end
  return filename:match("^(.+)%.[^%.]+$")
end

local function is_header(filepath)
  local ext = get_extension(filepath)
  if not ext then
    return false
  end
  for _, header_ext in ipairs(M.header_extensions) do
    if ext == header_ext then
      return true
    end
  end
  return false
end

local function is_source(filepath)
  local ext = get_extension(filepath)
  if not ext then
    return false
  end
  for _, source_ext in ipairs(M.source_extensions) do
    if ext == source_ext then
      return true
    end
  end
  return false
end

M.is_header = is_header
M.is_source = is_source

function M.get_file_type(filepath)
  if is_header(filepath) then
    return "header"
  elseif is_source(filepath) then
    return "source"
  end
  return nil
end

function M.get_project_root()
  local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
  if vim.v.shell_error == 0 and git_root then
    return git_root
  end
  return vim.fn.getcwd()
end

function M.parse_local_includes(source_path)
  local includes = {}
  local file = io.open(source_path, "r")
  if not file then
    return includes
  end

  for line in file:lines() do
    local include = line:match('#%s*include%s*"([^"]+)"')
    if include then
      local include_basename = include:match("([^/]+)$")
      table.insert(includes, include_basename)
    end
  end

  file:close()
  return includes
end

function M.find_matching_files(filepath)
  local basename = get_basename(filepath)
  if not basename then
    return {}
  end

  local file_type = M.get_file_type(filepath)
  if not file_type then
    return {}
  end

  local search_extensions
  if file_type == "header" then
    search_extensions = M.source_extensions
  else
    search_extensions = M.header_extensions
  end

  local root = M.get_project_root()
  local matches = {}

  for _, ext in ipairs(search_extensions) do
    local pattern = basename .. "." .. ext
    local cmd = string.format("find %s -name %s -type f 2>/dev/null", vim.fn.shellescape(root), vim.fn.shellescape(pattern))
    local results = vim.fn.systemlist(cmd)
    if vim.v.shell_error == 0 then
      for _, match in ipairs(results) do
        if match and match ~= "" then
          table.insert(matches, match)
        end
      end
    end
  end

  return matches
end

function M.find_best_match(filepath, candidates)
  if #candidates == 0 then
    return nil
  end

  if #candidates == 1 then
    return candidates[1]
  end

  local file_type = M.get_file_type(filepath)

  if file_type == "header" then
    local header_filename = filepath:match("([^/]+)$")
    for _, source_path in ipairs(candidates) do
      local includes = M.parse_local_includes(source_path)
      for _, include in ipairs(includes) do
        if include == header_filename then
          return source_path
        end
      end
    end
  else
    local includes = M.parse_local_includes(filepath)
    for _, header_path in ipairs(candidates) do
      local header_filename = header_path:match("([^/]+)$")
      for _, include in ipairs(includes) do
        if include == header_filename then
          return header_path
        end
      end
    end
  end

  return candidates[1]
end

function M.find_pair(filepath)
  local absolute_path = vim.fn.fnamemodify(filepath, ":p")
  local candidates = M.find_matching_files(absolute_path)
  return M.find_best_match(absolute_path, candidates)
end

return M
