---
tagline: extensible UI toolkit
---

## `local ui = require'ui'`

Extensible UI toolkit written in Lua with layouts, styles and animations.

## Features:

  * layouts: constraint-based, container-based and typesetting
  * cascading styles
  * animations based on tweens and timelines
  * layers
  * extensible

## API

--------------------------------- -----------------------------------------------
__ui__
`ui() -> ui`                      create a new UI module with its own stylesheet
__selectors__
`ui:find(sel) -> el`              find elements based on a selector
`el:each(f)`                      call `f` for each element
`ui:each(sel, f)`                 find elements and run `f` for each element
__styles__
`ui:style(sel, attrs)`            create a style
__windows__
`ui:window(win_t) -> window`      create a new UI state for a window
`win_t.window`                    [nw]-like window to bind to
`window:free()`                   detach the UI state from the window
__layers__
`window.hot_layer`                hot element: mouse is over it
__elements__
`e{id}`
`e{parent}`
`e{tags}`
`e.tags -> {tag->true, tag,...}`  tags table (both as array and as keys)
`e:settag(tag[, i][, op])`        add/remove/move tag
__extending__
`ui.object`                       the base class of all other classes
`ui.element`                      the base class for all widgets
`ui:draw()`                       draw the UI (called on window's `repaint.ui`)
`ui:mousemove(x, y)`              mouse moved (called on window's `mousemove.ui`)
`ui.selector`                     the element selector class
`ui.stylesheet`                   the stylsheet class
`ui.element_index`
`ui.element_list`
--------------------------------- -----------------------------------------------

