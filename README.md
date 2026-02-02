# Header source pair

Header source pair is an nvim plugin that will open both the header and source file in a split view. It integrates with telescope, so you
can fuzzy find a header or source file and this plugin will open the header on the left and source on the right.

How does the plugin handle different window configurations?
If the nvim already has a vertical split, the exiting windows will be reused. If there is more than 2 windows, only the first two windows
will be used. If there is only one window, a new vsplit will be opened to show the source file.

How does the plugin find the relevant source or header file?
The plugin will look for the source/header with the same name (without the extension). If there are multiple matches, the plugin will look
at the source file to see what header is included and show only the header that gets included.


