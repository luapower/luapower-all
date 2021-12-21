---
tagline: Excel XLSX file generator
author: John McNamara
license: MIT
---

## `local xlsxwriter = require'xlsxwriter'`

Xlsxwriter is a Lua module that can be used to write text, numbers, formulas
and hyperlinks to multiple worksheets in an Excel 2007+ XLSX file.

### Features

* High degree of fidelity with files produced by Excel.
* Can write very large files with semi-constant memory.
* Full formatting.
* Merged cells.
* Worksheet setup methods.
* Defined names.
* Document properties.

### Limitations

 * It can only create **new files**. It cannot read or modify existing files.

## Status

Xlsxwriter was written by John McNamara and published
[here](https://github.com/jmcnamara/xlsxwriter.lua). The module is no
longer maintained by the original author. This fork is maintained by
Cosmin Apreutesei.

Xlsxwriter is a Lua port of the Perl
[Excel::Writer::XLSX](http://search.cpan.org/~jmcnamara/Excel-Writer-XLSX/)
and the Python [XlsxWriter](http://xlsxwriter.readthedocs.org) modules.

## Example

![](/files/luapower/xlsxwriter/_images/demo.png)

```lua
local Workbook = require "xlsxwriter.workbook"

local workbook  = Workbook:new("demo.xlsx")
local worksheet = workbook:add_worksheet()

-- Widen the first column to make the text clearer.
worksheet:set_column("A:A", 20)

-- Add a bold format to use to highlight cells.
local bold = workbook:add_format({bold = true})

-- Write some simple text.
worksheet:write("A1", "Hello")

-- Text with formatting.
worksheet:write("A2", "World", bold)

-- Write some numbers, with row/column notation.
worksheet:write(2, 0, 123)
worksheet:write(3, 0, 123.456)

workbook:close()

```

