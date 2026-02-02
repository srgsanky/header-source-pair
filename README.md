# header-source-pair

> This plugin was implemented entirely by prompting [Claude](https://claude.ai) using [Claude Code](https://claude.ai/claude-code).

A Neovim plugin for C/C++ development that opens header and source files side by side in a split view. Integrates with Telescope for fuzzy finding.

## Features

- Open header/source pairs in a vertical split (header on left, source on right)
- Telescope picker to find and open any C/C++ file with its pair
- Recent pairs history (project-specific) for quick switching
- Open pairs from `#include` statements under cursor
- Smart matching using `#include` analysis when multiple candidates exist

## Window Behavior

| Current Layout | Action |
|----------------|--------|
| Single window | Creates a new vsplit |
| Two+ windows | Reuses the first two windows |

## File Matching

The plugin finds pairs by matching the base filename (without extension). When multiple matches exist, it parses `#include "..."` statements to determine the correct pair.

## Design Decisions

**Supported Languages:** C and C++ only

**File Extensions:**
- Headers: `.h`, `.hpp`, `.hxx`, `.hh`, `.H`
- Sources: `.c`, `.cpp`, `.cc`, `.cxx`, `.C`

**Search Scope:** Searches the entire project (from git root or cwd), as most projects don't keep headers and sources in the same directory.

**Include Parsing:** Parses only local includes (`#include "..."`) to determine header-source relationships. System includes (`#include <...>`) are ignored.

**Why not use LSP?** Simple parsing keeps the plugin lightweight and functional without dependencies. LSP would be more accurate (respects `compile_commands.json` and include paths) but adds complexity. May add optional LSP support in the future.

**No Match Behavior:** When a header has no matching source (e.g., header-only libraries) or vice versa, the plugin opens just the single file without splitting.

**Implementation:** Pure Lua for simplicity and maintainability.

## Project Structure

```
lua/
  header-source-pair/
    init.lua       -- Setup, config, and :HeaderSourcePair command
    finder.lua     -- File matching and include parsing logic
    window.lua     -- Window split management
    recent.lua     -- Recent pairs history (project-specific)
  telescope/
    _extensions/
      header_source_pair.lua  -- Telescope pickers (find pairs, recent pairs)
```

**Key implementation details:**
- `finder.lua:65` - Parses local includes from source files
- `finder.lua:82` - Searches project for matching files
- `finder.lua:107` - Determines best match using include analysis
- `window.lua:19` - Handles split window logic
- `recent.lua` - Stores history per project in `~/.local/share/nvim/header-source-pair/<project-hash>/`

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "your-username/header-source-pair",
  dependencies = {
    "nvim-telescope/telescope.nvim", -- optional, for fuzzy finding
  },
  config = function()
    require("header-source-pair").setup()
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "your-username/header-source-pair",
  requires = { "nvim-telescope/telescope.nvim" }, -- optional
  config = function()
    require("header-source-pair").setup()
  end,
}
```

## Usage

### Commands

```vim
:HeaderSourcePair
```
Opens the current buffer's file and its matching header/source in a split view.

```vim
:HeaderSourcePairCursor
```
Opens the pair for the `#include` under the cursor. Useful when browsing include statements.

### Telescope Integration

Find all C/C++ files and open with their pair:
```vim
:Telescope header_source_pair
```

Browse recently opened pairs (project-specific history):
```vim
:Telescope header_source_pair recent
```

Or in Lua:
```lua
require("telescope").extensions.header_source_pair.header_source_pair()
require("telescope").extensions.header_source_pair.recent()
```

### Keybinding Example

```lua
-- If you're editing calculator.cpp and press <leader>hs, it opens calculator.h alongside it
vim.keymap.set("n", "<leader>hs", "<cmd>HeaderSourcePair<cr>", { desc = "Open header/source pair for current buffer" })

-- Open pair for the #include under cursor
vim.keymap.set("n", "<leader>hc", "<cmd>HeaderSourcePairCursor<cr>", { desc = "Open header/source pair under cursor" })

vim.keymap.set("n", "<leader>fp", "<cmd>Telescope header_source_pair<cr>", { desc = "[f]ind [p]airs" })
vim.keymap.set("n", "<leader>fr", "<cmd>Telescope header_source_pair recent<cr>", { desc = "[f]ind [r]ecent pairs" })
```

## Configuration

```lua
require("header-source-pair").setup({
  -- Customize file extensions (optional)
  header_extensions = { "h", "hpp", "hxx", "hh", "H" },
  source_extensions = { "c", "cpp", "cc", "cxx", "C" },
})
```

## Testing

A test project is included to verify the plugin works correctly.

**Test project structure:**
```
test-project/
  include/
    calculator.h    -- pairs with src/calculator.cpp
    utils.h         -- pairs with src/utils.cpp
  src/
    calculator.cpp  -- includes "calculator.h"
    utils.cpp       -- includes "utils.h"
    main.cpp        -- no matching header (tests no-match case)
  test_plugin.lua   -- test script
```

**Running tests:**
```vim
:luafile test-project/test_plugin.lua
```

**What the tests verify:**
- File type detection (header/source) works correctly
- Include parsing extracts local includes properly
- Pair matching finds files across different directories
- No-match case correctly returns nil for files without pairs
- Finding files by name in project (for cursor feature)
- Recent pairs are stored and retrieved correctly
- New pairs appear at the top of the recent list
- Re-opening a pair moves it to the top (no duplicates)

**Interactive testing:**
1. Open neovim in the plugin directory
2. Open a test file: `:e test-project/src/calculator.cpp`
3. Run `:HeaderSourcePair` to see the split view with `calculator.h` on the left
