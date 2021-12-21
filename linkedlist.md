---
tagline: doubly linked lists in Lua
---

## `local list = require'linkedlist'`

Doubly linked lists in Lua. Doubly linked lists make insert, remove and move operations fast,
and access by index slow. In this particular implementation items must be Lua tables for which
fields `_prev` and `_next` must be reserved for linking.

## API

---------------------------------------------- ----------------------------------------------
`list() -> list`                               create a new list
`list:clear()`                                 clear the list
`list:insert_first(t)`                         add an item at beginning of the list
`list:insert_last(t)`                          add an item at the end of the list
`list:insert_after([anchor, ]t)`               add an item after another item (or at the end)
`list:insert_before([anchor, ]t)`              add an item before another item (or at the beginning)
`list:remove(t) -> t`                          remove a specific item (and return it)
`list:removel_last() -> t`                     remove and return the last item, if any
`list:remove_first() -> t`                     remove and return the first item, if any
`list:next([current]) -> t`                    next item after some item (or first item)
`list:prev([current]) -> t`                    previous item after some item (or last item)
`list:items() -> iterator<item>`               iterate items
`list:reverse_items() -> iterator<item>`       iterate items in reverse
`list:copy() -> new_list`                      copy the list
---------------------------------------------- ----------------------------------------------
