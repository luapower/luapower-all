---
tagline: codedit controller
---

## `editor_class = require'codedit_editor'`

## Properties

~~~{.lua}
--subclasses
buffer = buffer,
line_selection = line_selection,
block_selection = block_selection,
cursor = cursor,
line_numbers_margin = line_numbers_margin,
blame_margin = blame_margin,
view = view,
--margins
line_numbers = true,
blame = false,
--keyboard state
next_reflow_mode = {left = 'justify', justify = 'left'},
default_reflow_mode = 'left',
~~~

## Constructor

### `editor = editor_class:new(options)`

## Key Processing

### `require'editor_keys'`

Extends the editor with a default list of key bindings and a method of executing
an editor method given its key combination.

### `editor.key_bindings -> {[shortcut] = method_name]}`

The default list of key bindings. They map directly to editor method names.
The key modifiers are `ctrl`, `alt` and `shift` and must appear in this order.
For the full list of key names see [cplayer].

### `editor:perform_shortcut(shortcut)`

Execute an editor method by its key binding.

## Key Bindings

-------------------------------------------------- --------------------------------------------------
__navigation__
editor:scroll_up()											ctrl+up
editor:scroll_down()                               ctrl+down
editor:move_prev_pos()                             left
editor:move_next_pos()                             right
editor:move_prev_pos_unrestricted()                alt+left
editor:move_next_pos_unrestricted()                alt+right
editor:move_up()                                   up
editor:move_down()                                 down
editor:move_prev_word_break()                      ctrl+left
editor:move_next_word_break()                      ctrl+right
editor:move_bol()                                  home
editor:move_eol()                                  end
editor:move_home()                                 ctrl+home
editor:move_end()                                  ctrl+end
editor:move_up_page()                              pageup
editor:move_down_page()                            pagedown
__navigation + selection__
editor:select_prev_pos()                           shift+left
editor:select_next_pos()                           shift+right
editor:select_up()                                 shift+up
editor:select_down()                               shift+down
editor:select_prev_word_break()                    ctrl+shift+left
editor:select_next_word_break()                    ctrl+shift+right
editor:select_bol()                                shift+home
editor:select_eol()                                shift+end
editor:select_home()                               ctrl+shift+home
editor:select_end()                                ctrl+shift+end
editor:select_up_page()                            shift+pageup
editor:select_down_page()                          shift+pagedown
__navigation + block selection__
editor:select_block_prev_pos()                     alt+shift+left
editor:select_block_next_pos()                     alt+shift+right
editor:select_block_up()                           alt+shift+up
editor:select_block_down()                         alt+shift+down
editor:select_block_prev_word_break()              ctrl+alt+shift+left
editor:select_block_next_word_break()              ctrl+alt+shift+right
editor:select_block_bol()                          alt+shift+home
editor:select_block_eol()                          alt+shift+end
editor:select_block_home()                         ctrl+alt+shift+home
editor:select_block_end()                          ctrl+alt+shift+end
editor:select_block_up_page()                      alt+shift+pageup
editor:select_block_down_page()                    alt+shift+pagedown
__additional navigation__
editor:move_up_page()                              alt+up
editor:move_down_page()                            alt+down
__bookmarks (TODO)__
editor:toggle_bookmark()                           ctrl+f2
editor:move_next_bookmark()                        f2
editor:move_prev_bookmark()                        shift+f2
__additional selection__
editor:select_all()                                ctrl+A
__editing__
editor:toggle_insert_mode()                        insert
editor:delete_prev_pos()                           backspace
editor:delete_prev_pos()                           shift+backspace
editor:delete_pos()                                delete
editor:newline()                                   return
editor:indent()                                    tab
editor:outdent()                                   shift+tab
editor:move_lines_up()                             ctrl+shift+up
editor:move_lines_down()                           ctrl+shift+down
editor:undo()                                      ctrl+Z
editor:redo()                                      ctrl+Y
__reflowing__
editor:reflow()                                    ctrl+R
__copy/pasting__
editor:cut()                                       ctrl+X
editor:copy()                                      ctrl+C
editor:paste()                                     ctrl+V
editor:paste_block()                               ctrl+alt+V
__saving__
editor:save()                                      ctrl+S
-------------------------------------------------- --------------------------------------------------
