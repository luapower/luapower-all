---
tagline: loading X11 themed cursors
---

## `xcb_cursor = require'xcb_cursor'`

A binding of xcb/util-cursor plus libxcb-cursor binaries to be used in
conjunction with [xcb] to load themed cursors.

Loaded automatically at runtime by `xcb.load_cursor()`.

## API

------------------------------------------ -----------------------------------
`xcb_cursor.context(conn, screen) -> ctx`  get a context
`ctx:free()`                               free the context
`ctx:load(cursor_name) -> cursor | nil`    load a themed cursor
------------------------------------------ -----------------------------------

The loaded cursor can be set on a window with `xcb.set_cursor()`.
