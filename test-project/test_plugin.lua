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

print("\n=== Tests complete ===\n")
