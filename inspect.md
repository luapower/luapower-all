---
tagline: table dump
---

## `require'inspect'(t[, options])`

Dumps Lua tables in human-readable format. The output is for debugging, not serialization (use [pp] for that).

Features:

  * array-like tables are rendered horizontally.
  * dictionary-like tables are rendered with one element per line.
  * mixed tables have the array part on the first line, and the dictionary part just below.
  * keys are sorted alphanumerically when possible.
  * subtables are indented with two spaces per level (configurable).
  * functions, userdata and cdata print as `<function x>`, `<userdata x>`, etc.
  * metatables are added at the end, in a special field called `<metatable>`.
  * handles recursive references: prints `<id>` right before the table is printed out the 
  first time, and replaces the whole table with `<table id>` from then on, preventing infinite loops.

### Options

  * `options.depth`: sets the maximum depth that will be printed out before printing just `{...}`:
  * `options.newline` & `options.indent`: strings to use as newline and indent.
  * `options.process`: filter/format function.
  * `options.process`: `function(item, path)` where:
    * `item` is either a key or a value on the table, or any of its subtables
    * `path` is an array-like table built with all the keys that have been used to reach `item`, from the root.
    * For values, it is just a regular list of keys. For example, to reach the 1 in `{a = {b = 1}}`, the `path`
    will be `{'a', 'b'}`
    * For keys, the special value `inspect.KEY` is inserted. For example, to reach the `c` in `{a = {b = {c = 1}}}`,
    the path will be `{'a', 'b', 'c', inspect.KEY }`
    * For metatables, the special value `inspect.METATABLE` is inserted. For `{a = {b = 1}}}`, the path
    `{'a', {b = 1}, inspect.METATABLE}` means "the metatable of the table `{b = 1}`".
    * `processed_item` is the value returned by `options.process`. If it is equal to `item`, then the inspected
    table will look unchanged. If it is different, then the table will look different; most notably, if it's `nil`,
    the item will dissapear on the inspected table.

#### Filtering Examples

Remove a particular metatable from the result:

``` lua
local t = {1,2,3}
local mt = {b = 2}
setmetatable(t, mt)

local remove_mt = function(item)
  if item ~= mt then return item end
end

-- mt does not appear
assert(inspect(t, {process = remove_mt}) == "{ 1, 2, 3 }")
```

The previous exaple only works for a particular metatable. If you want to make *all* metatables, you can use the `path` parameter to check
wether the last element is `inspect.METATABLE`, and return `nil` instead of the item:

``` lua
local t, mt = ... -- (defined as before)

local remove_all_metatables = function(item, path)
  if path[#path] ~= inspect.METATABLE then return item end
end

assert(inspect(t, {process = remove_all_metatables}) == "{ 1, 2, 3 }")
```

Filter a value:

```lua
local anonymize_password = function(item, path)
  if path[#path] == 'password' then return "XXXX" end
  return item
end

local info = {user = 'peter', password = 'secret'}

assert(inspect(info, {process = anonymize_password}) == [[{
  password = "XXXX",
  user     = "peter"
}]])
```
