----
--
-- An example of indenting text in a cell using the xlsxwriter.lua module.
--
-- Copyright 2014-2015, John McNamara, jmcnamara@cpan.org
--

local Workbook = require "xlsxwriter.workbook"

local workbook  = Workbook:new("text_indent.xlsx")
local worksheet = workbook:add_worksheet()

local indent1 = workbook:add_format({indent = 1})
local indent2 = workbook:add_format({indent = 2})

worksheet:set_column("A:A", 40)

worksheet:write("A1", "This text is indented 1 level",  indent1)
worksheet:write("A2", "This text is indented 2 levels", indent2)

workbook:close()
