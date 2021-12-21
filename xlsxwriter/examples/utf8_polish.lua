----
--
-- A simple example of converting some Unicode text to an Excel file using
-- the xlsxwriter.lua module.
--
-- This example generates a spreadsheet with some Polish text from a file
-- with UTF-8 encoded text.
--
-- Copyright 2014-2015, John McNamara, jmcnamara@cpan.org
--

local Workbook = require "xlsxwriter.workbook"

local workbook  = Workbook:new("utf8_polish.xlsx")
local worksheet = workbook:add_worksheet()

-- Widen the first column to make the text clearer.
worksheet:set_column("A:A", 50)

-- Open a source of UTF-8 data.
local file = assert(io.open("utf8_polish.txt", "r"))

-- Read the text file and write it to the worksheet.
local line = file:read("*l")
local row = 0

while line do
  -- Ignore comments in the text file.
  if not string.match(line, "^#") then
    worksheet:write(row, 0, line)
    row = row + 1
  end
  line = file:read("*l")
end

workbook:close()
