---
tagline: doubly linked lists
---

## `local dlist = require'dlist'`

Doubly linked lists in Lua. Doubly linked lists make insert, remove and move operations fast,
and access by index slow. In this particular implementation items must be Lua tables for which
fields `_prev` and `_next` must be reserved for linking.

---------------------------------------------- ----------------------------------------------
`dlist() -> list`<br> `dlist:new() -> list`    create a new list
`list:clear()`                                 clear the list
`list:push(t)`                                 add an item at end of the list
`list:unshift(t)`                              add an item at the beginning of the list
`list:insert(t[, after_t])`                    add an item after another item (or at the end)
`list:pop() -> t`                              remove and return the last item, if any
`list:shift() -> t`                            remove and return the first item, if any
`list:remove(t) -> t`                          remove and return a specific item
`list:next([current]) -> t`                    next item after some item (or first item)
`list:prev([current]) -> t`                    previous item after some item (or last item)
`list:items() -> iterator<item>`               iterate items
`list:reverse_items() -> iterator<item>`       iterate items in reverse
`list:copy() -> new_list`                      copy the list
---------------------------------------------- ----------------------------------------------
