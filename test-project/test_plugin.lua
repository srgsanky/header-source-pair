-- Test script for header-source-pair plugin
-- Run from neovim with: :luafile test-project/test_plugin.lua

local cwd = vim.fn.getcwd()

-- Clear module cache and load fresh from plugin directory
package.loaded["header-source-pair.finder"] = nil
package.loaded["header-source-pair.recent"] = nil
package.loaded["header-source-pair.window"] = nil
package.loaded["header-source-pair"] = nil

-- Load finder directly and inject into package.loaded so other modules use it
local finder = dofile(cwd .. "/lua/header-source-pair/finder.lua")
package.loaded["header-source-pair.finder"] = finder

local function test(name, condition)
  if condition then
    print("✓ " .. name)
  else
    print("✗ " .. name)
  end
end

print("\n=== header-source-pair tests ===\n")

-- Test file type detection
test("calculator.h is header", finder.is_header("calculator.h"))
test("calculator.cpp is source", finder.is_source("calculator.cpp"))
test("calculator.hpp is header", finder.is_header("calculator.hpp"))
test("calculator.c is source", finder.is_source("calculator.c"))
test("calculator.txt is not header", not finder.is_header("calculator.txt"))
test("calculator.txt is not source", not finder.is_source("calculator.txt"))

-- Test get_file_type
test("get_file_type header", finder.get_file_type("test.h") == "header")
test("get_file_type source", finder.get_file_type("test.cpp") == "source")
test("get_file_type unknown", finder.get_file_type("test.txt") == nil)

-- Test include parsing
local test_dir = vim.fn.getcwd() .. "/test-project"
local includes = finder.parse_local_includes(test_dir .. "/src/calculator.cpp")
test("parse includes finds calculator.h", vim.tbl_contains(includes, "calculator.h"))

local main_includes = finder.parse_local_includes(test_dir .. "/src/main.cpp")
test("parse main.cpp includes calculator.h", vim.tbl_contains(main_includes, "calculator.h"))
test("parse main.cpp includes utils.h", vim.tbl_contains(main_includes, "utils.h"))

-- Test find_pair
local pair = finder.find_pair(test_dir .. "/include/calculator.h")
test("find_pair for calculator.h finds calculator.cpp", pair and pair:match("calculator%.cpp$") ~= nil)

local pair2 = finder.find_pair(test_dir .. "/src/utils.cpp")
test("find_pair for utils.cpp finds utils.h", pair2 and pair2:match("utils%.h$") ~= nil)

-- Test no match case (main.cpp has no header)
local pair3 = finder.find_pair(test_dir .. "/src/main.cpp")
test("find_pair for main.cpp returns nil", pair3 == nil)

-- Test find_file_in_project (used by HeaderSourcePairCursor)
local found_header = finder.find_file_in_project("calculator.h")
test("find_file_in_project finds calculator.h", found_header and found_header:match("calculator%.h$") ~= nil)

local found_source = finder.find_file_in_project("utils.cpp")
test("find_file_in_project finds utils.cpp", found_source and found_source:match("utils%.cpp$") ~= nil)

local not_found = finder.find_file_in_project("nonexistent.h")
test("find_file_in_project returns nil for missing file", not_found == nil)

print("\n=== Recent pairs tests ===\n")

local recent = dofile(cwd .. "/lua/header-source-pair/recent.lua")
package.loaded["header-source-pair.recent"] = recent

-- Clear any existing test data by getting fresh state
local initial_pairs = recent.get_pairs()
local initial_count = #initial_pairs

-- Test adding a pair
recent.add_pair("/test/foo.h", "/test/foo.cpp")
local pairs_after_add = recent.get_pairs()
test("add_pair increases count", #pairs_after_add == initial_count + 1)

-- Test that new pair is at the top
test("new pair is first in list", pairs_after_add[1].header == "/test/foo.h" and pairs_after_add[1].source == "/test/foo.cpp")

-- Test that pair has timestamp
test("pair has timestamp", pairs_after_add[1].timestamp ~= nil and pairs_after_add[1].timestamp > 0)

-- Test adding another pair
recent.add_pair("/test/bar.h", "/test/bar.cpp")
local pairs_after_second = recent.get_pairs()
test("second pair is now first", pairs_after_second[1].header == "/test/bar.h")
test("first pair is now second", pairs_after_second[2].header == "/test/foo.h")

-- Test duplicate handling (re-adding foo should move it to top)
recent.add_pair("/test/foo.h", "/test/foo.cpp")
local pairs_after_dup = recent.get_pairs()
test("re-adding pair moves it to top", pairs_after_dup[1].header == "/test/foo.h")
test("no duplicate entries", #pairs_after_dup == #pairs_after_second)

-- Test that bar is now second
test("previous first is now second", pairs_after_dup[2].header == "/test/bar.h")

-- Clean up test entries
local function remove_test_entries()
  local pairs = recent.get_pairs()
  local cleaned = {}
  for _, p in ipairs(pairs) do
    if not p.header:match("^/test/") then
      table.insert(cleaned, p)
    end
  end
  -- Rewrite the file with cleaned data
  local data_dir = vim.fn.stdpath("data")
  local root = finder.get_project_root()
  local hash = vim.fn.sha256(root):sub(1, 16)
  local path = data_dir .. "/header-source-pair/" .. hash .. "/recent.json"
  local file = io.open(path, "w")
  if file then
    file:write(vim.fn.json_encode(cleaned))
    file:close()
  end
end
remove_test_entries()

local pairs_after_cleanup = recent.get_pairs()
test("cleanup removed test entries", #pairs_after_cleanup == initial_count)

print("\n=== Configuration tests ===\n")

-- Load window module
local window = dofile(cwd .. "/lua/header-source-pair/window.lua")
package.loaded["header-source-pair.window"] = window

-- Load main module
local hsp = dofile(cwd .. "/lua/header-source-pair/init.lua")
package.loaded["header-source-pair"] = hsp

-- Test default config values
test("default split is vertical", hsp.config.split == "vertical")
test("default header_percent is 50", hsp.config.header_percent == 50)

-- Test setup with custom config
hsp.setup({
  split = "horizontal",
  header_percent = 70,
})
test("config split updates to horizontal", hsp.config.split == "horizontal")
test("config header_percent updates to 70", hsp.config.header_percent == 70)
test("window module receives split config", window.config.split == "horizontal")
test("window module receives header_percent config", window.config.header_percent == 70)

-- Reset to defaults for other tests
hsp.config.split = "vertical"
hsp.config.header_percent = 50
window.config = hsp.config

print("\n=== Window tests ===\n")

-- Close all windows except one
vim.cmd("only")
local initial_win_count = #vim.api.nvim_tabpage_list_wins(0)
test("starts with single window", initial_win_count == 1)

-- Open a pair and check window count
window.open_pair(test_dir .. "/include/calculator.h", test_dir .. "/src/calculator.cpp")
local after_split_count = #vim.api.nvim_tabpage_list_wins(0)
test("opening pair creates two windows", after_split_count == 2)

-- Check that both files are loaded in buffers
local wins = vim.api.nvim_tabpage_list_wins(0)
local buf1 = vim.api.nvim_win_get_buf(wins[1])
local buf2 = vim.api.nvim_win_get_buf(wins[2])
local name1 = vim.api.nvim_buf_get_name(buf1)
local name2 = vim.api.nvim_buf_get_name(buf2)
local has_header = name1:match("calculator%.h$") or name2:match("calculator%.h$")
local has_source = name1:match("calculator%.cpp$") or name2:match("calculator%.cpp$")
test("header file is open in a window", has_header ~= nil)
test("source file is open in a window", has_source ~= nil)

-- Test reusing existing windows
window.open_pair(test_dir .. "/include/utils.h", test_dir .. "/src/utils.cpp")
local after_reuse_count = #vim.api.nvim_tabpage_list_wins(0)
test("opening another pair reuses windows (still 2)", after_reuse_count == 2)

-- Clean up
vim.cmd("only")
vim.cmd("enew")

print("\n=== Tests complete ===\n")
