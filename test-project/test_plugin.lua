-- Test script for header-source-pair plugin
-- Run from neovim with: :luafile test-project/test_plugin.lua

-- Add plugin to runtime path
vim.opt.runtimepath:prepend(vim.fn.getcwd())

local finder = require("header-source-pair.finder")

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

print("\n=== Recent pairs tests ===\n")

local recent = require("header-source-pair.recent")

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

print("\n=== Tests complete ===\n")
