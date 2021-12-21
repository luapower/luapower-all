----
--
-- Example of how to use the xlsxwriter.lua module to write
-- simple array formulas.
--
-- Copyright 2014-2015, John McNamara, jmcnamara@cpan.org
--

local Workbook = require "xlsxwriter.workbook"

-- Create a new workbook and add a worksheet
local workbook  = Workbook:new("array_formula.xlsx")
local worksheet = workbook:add_worksheet()

-- Write some test data.
worksheet:write("B1", 500)
worksheet:write("B2", 10)
worksheet:write("B5", 1)
worksheet:write("B6", 2)
worksheet:write("B7", 3)
worksheet:write("C1", 300)
worksheet:write("C2", 15)
worksheet:write("C5", 20234)
worksheet:write("C6", 21003)
worksheet:write("C7", 10000)

-- Write an array formula that returns a single value
worksheet:write_formula("A1", "{=SUM(B1:C1*B2:C2)}")

-- Same as above but more explicit.
worksheet:write_array_formula("A2:A2", "{=SUM(B1:C1*B2:C2)}")

-- Write an array formula that returns a range of values
worksheet:write_array_formula("A5:A7", "{=TREND(C5:C7,B5:B7)}")

workbook:close()
