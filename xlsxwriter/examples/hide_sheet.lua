----
--
-- Example of how to hide a worksheet with xlsxwriter.lua.
--
-- Copyright 2014-2015, John McNamara, jmcnamara@cpan.org
--

local Workbook = require "xlsxwriter.workbook"

local workbook = Workbook:new("hide_sheet.xlsx")

local worksheet1 = workbook:add_worksheet()
local worksheet2 = workbook:add_worksheet()
local worksheet3 = workbook:add_worksheet()

worksheet1:set_column("A:A", 30)
worksheet2:set_column("A:A", 30)
worksheet3:set_column("A:A", 30)

-- Hide Sheet2. It won't be visible until it is unhidden in Excel.
worksheet2:hide()

worksheet1:write("A1", "Sheet2 is hidden")
worksheet2:write("A1", "Now it's my turn to find you!")
worksheet3:write("A1", "Sheet2 is hidden")

workbook:close()
