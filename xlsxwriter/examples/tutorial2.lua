----
--
-- A simple program to write some data to an Excel file using the
-- xlsxwriter.lua module.
--
-- This program is shown, with explanations, in Tutorial 2 of the xlsxwriter
-- documentation.
--
-- Copyright 2014-2015, John McNamara, jmcnamara@cpan.org
--

local Workbook = require "xlsxwriter.workbook"


-- Create a workbook and add a worksheet.
local workbook  = Workbook:new("Expensese02.xlsx")
local worksheet = workbook:add_worksheet()

-- Add a bold format to use to highlight cells.
local bold = workbook:add_format({bold = true})

-- Add a number format for cells with money.
local money = workbook:add_format({num_format = "$#,##0"})

-- Write some data header.
worksheet:write("A1", "Item", bold)
worksheet:write("B1", "Cost", bold)

-- Some data we want to write to the worksheet.
local expenses = {
  {"Rent", 1000},
  {"Gas",   100},
  {"Food",  300},
  {"Gym",    50},
}

-- Start from the first cell below the headers.
local row = 1
local col = 0

-- Iterate over the data and write it out element by element.
for _, expense in ipairs(expenses) do
  local item, cost = unpack(expense)
  worksheet:write(row, col,     item)
  worksheet:write(row, col + 1, cost, money)
  row = row + 1
end

-- Write a total using a formula.
worksheet:write(row, 0, "Total",       bold)
worksheet:write(row, 1, "=SUM(B2:B5)", money)

workbook:close()
