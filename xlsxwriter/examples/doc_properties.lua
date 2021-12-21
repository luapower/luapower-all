----
--
-- An example of adding document properites to a xlsxwriter.lua file.
--
-- Copyright 2014-2015, John McNamara, jmcnamara@cpan.org
--

local Workbook = require "xlsxwriter.workbook"

local workbook  = Workbook:new("doc_properties.xlsx")
local worksheet = workbook:add_worksheet()

workbook:set_properties({
    title    = "This is an example spreadsheet",
    subject  = "With document properties",
    author   = "Someone",
    manager  = "Dr. Heinz Doofenshmirtz",
    company  = "of Wolves",
    category = "Example spreadsheets",
    keywords = "Sample, Example, Properties",
    comments = "Created with Lua and the xlsxwriter module",
    status   = "Quo",
})

worksheet:set_column("A:A", 70)
worksheet:write("A1", "Select 'Workbook Properties' to see properties.")

workbook:close()
