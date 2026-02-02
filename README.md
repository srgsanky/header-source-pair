# Header source pair

Header source pair is an nvim plugin that will open both the header and source file in a split view. It integrates with telescope, so you
can fuzzy find a header or source file and this plugin will open the header on the left and source on the right.

How does the plugin handle different window configurations?
If the nvim already has a vertical split, the exiting windows will be reused. If there is more than 2 windows, only the first two windows
will be used. If there is only one window, a new vsplit will be opened to show the source file.

How does the plugin find the relevant source or header file?
The plugin will look for the source/header with the same name (without the extension). If there are multiple matches, the plugin will look
at the source file to see what header is included and show only the header that gets included.

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

### Command

```vim
:HeaderSourcePair
```

Opens the current file and its matching header/source in a split view.

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
- Recent pairs are stored and retrieved correctly
- New pairs appear at the top of the recent list
- Re-opening a pair moves it to the top (no duplicates)

**Interactive testing:**
1. Open neovim in the plugin directory
2. Open a test file: `:e test-project/src/calculator.cpp`
3. Run `:HeaderSourcePair` to see the split view with `calculator.h` on the left
