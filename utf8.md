---
tagline: UTF-8 in Lua
---

## `local utf8 = require'utf8'`

Low-level module for working with UTF-8 encoded strings. Byte indices are i's, char indices are ci's, and "char" means unicode codepoint.
Invalid characters are counted as 1-byte chars so they don't get lost. Validate/sanitize beforehand as needed.

## API

------------------------------------------------- -------------------------------------------------
`utf8.byte_indices(s) -> iterator<i, valid>`      iterate the chars in a string, returning the byte index followed by a valid flag[^1], for each char.
`utf8.byte_indices_reverse(s) -> iterator<i>`     iterate the chars in a string in reverse, returning the byte index of each char.
`utf8.next(s, last_i) -> i, isvalid | nil`        byte index of the next char after the char at byte index i, followed by a valid flag`***`. nil if out of range.
`utf8.prev(s, i) -> prev_i`                       byte index of the prev. char before the char at byte index i, or nil if i is out of range.
`utf8.byte_index(s, target_ci) -> i`              byte index given char index. nil if the index is out of range.
`utf8.char_index(s, target_i) -> ci`              char index given byte index. nil if the index is out of range.
`utf8.len(s) -> len`                              number of chars in string
`utf8.sub(s, start_ci[, end_ci]) -> s`            sub based on char indices (also, start_ci must be >= 1 and end_ci, if given, can't be negative)
`utf8.contains(s, i, sub) -> true|false`          check if a string contains a substring at byte index i
`utf8.count(s, sub) -> n`                         count the number of occurences of a substring in a string
`utf8.isvalid(s, i) -> true|false`                check if there's a valid utf8 codepoint at byte index i
`utf8.valid_byte_indices(s) -> iterator<i>`       iterate valid chars, returning the byte index where each char starts.
`utf8.next_valid(s, last_i) -> i | nil`           byte index of the next valid utf8 char after the char at byte index i. nil if out of range. invalid chars are skipped.
`utf8.validate(s)`                                assert that a string only contains valid utf8 characters; raise an error if that's not the case
------------------------------------------------- -------------------------------------------------

[^1]: when iterating, validation only performed on the first byte. to fully validate that a utf8 codepoint is within the accepted range, use `utf8.isvalid()`.

## Extending

At the heart of the module is the `utf8.next` function, which you can redefine for different semantics.
In particular, you can reassign `utf8.next` to `utf8.next_valid` to change the behavior of the entire module to skip on invalid indices.
Preferably you would not do that directly on the module table returned by `require`, but make a new module instead:

`my_utf8.lua`:

~~~{.lua}
local glue = require'glue'
local utf8 = require'utf8'
return glue.merge({utf8.next = utf8.next_valid}, utf8)
~~~
