----
--
-- A simple program to write some data to an Excel file using the
-- xlsxwriter.lua module.
--
-- This program is shown, with explanations, in Tutorial 3 of the xlsxwriter
-- documentation.
--
-- Copyright 2014-2015, John McNamara, jmcnamara@cpan.org
--

local Workbook = require "xlsxwriter.workbook"


-- Create a workbook and add a worksheet.
local workbook  = Workbook:new("Expensese03.xlsx")
local worksheet = workbook:add_worksheet()

-- Add a bold format to use to highlight cells.
local bold = workbook:add_format({bold = true})

-- Add a number format for cells with money.
local money = workbook:add_format({num_format = "$#,##0"})

-- Add an Excel date format.
local date_format = workbook:add_format({num_format = "mmmm d yyyy"})

-- Adjust the column width.
worksheet:set_column('B:B', 15)

-- Write some data header.
worksheet:write("A1", "Item", bold)
worksheet:write("B1", "Date", bold)
worksheet:write("C1", "Cost", bold)

-- Some data we want to write to the worksheet.
local expenses = {
  {"Rent", "2013-01-13", 1000},
  {"Gas",  "2013-01-14",  100},
  {"Food", "2013-01-16",  300},
  {"Gym",  "2013-01-20",   50},
}

-- Start from the first cell below the headers.
local row = 1
local col = 0

-- Iterate over the data and write it out element by element.
for _, expense in ipairs(expenses) do
  local item, date, cost = unpack(expense)

  worksheet:write_string     (row, col,     item)
  worksheet:write_date_string(row, col + 1, date, date_format)
  worksheet:write_number     (row, col + 2, cost, money)
  row = row + 1
end

-- Write a total using a formula.
worksheet:write(row, 0, "Total",       bold)
worksheet:write(row, 2, "=SUM(C2:C5)", money)

workbook:close()
