----
--
-- Example of how to create defined names with the xlsxwriter.lua module.
--
-- This method is used to define a user friendly name to represent a value,
-- a single cell or a range of cells in a workbook.
--
-- Copyright 2014-2015, John McNamara, jmcnamara@cpan.org
--

local Workbook = require "xlsxwriter.workbook"

local workbook   = Workbook:new("defined_name.xlsx")
local worksheet1 = workbook:add_worksheet()
local worksheet2 = workbook:add_worksheet()

-- Define some global/workbook names.
workbook:define_name("Exchange_rate", "=0.96")
workbook:define_name("Sales", "=Sheet1!$G$1:$H$10")

-- Define a local/worksheet name. Over-rides the "Sales" name above.
workbook:define_name("Sheet2!Sales", "=Sheet2!$G$1:$G$10")

-- Write some text in the file and one of the defined names in a formula.
for _, worksheet in ipairs(workbook:worksheets()) do
  worksheet:set_column("A:A", 45)

  worksheet:write("A1", "This worksheet contains some defined names.")
  worksheet:write("A2", "See Formulas -> Name Manager above.")
  worksheet:write("A3", "Example formula in cell B3 ->")

  worksheet:write("B3", "=Exchange_rate")
end

workbook:close()
