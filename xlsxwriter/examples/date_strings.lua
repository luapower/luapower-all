----
--
-- A simple program to write some dates and times to an Excel file
-- using the xlsxwriter.lua module.
--
-- Copyright 2014-2015, John McNamara, jmcnamara@cpan.org
--

local Workbook = require "xlsxwriter.workbook"

local workbook  = Workbook:new("date_strings.xlsx")
local worksheet = workbook:add_worksheet()
local bold      = workbook:add_format({bold = true})

-- Expand the first columns so that the date is visible.
worksheet:set_column("A:B", 30)

-- Write the column headers.
worksheet:write("A1", "Formatted date", bold)
worksheet:write("B1", "Format",         bold)

-- Create an ISO8601 style date string to use in the examples.
local date_string = "2013-01-23T12:30:05.123"

-- Examples date and time formats. In the output file compare how changing
-- the format codes change the appearance of the date.
local date_formats = {
  "dd/mm/yy",
  "mm/dd/yy",
  "dd m yy",
  "d mm yy",
  "d mmm yy",
  "d mmmm yy",
  "d mmmm yyy",
  "d mmmm yyyy",
  "dd/mm/yy hh:mm",
  "dd/mm/yy hh:mm:ss",
  "dd/mm/yy hh:mm:ss.000",
  "hh:mm",
  "hh:mm:ss",
  "hh:mm:ss.000",
}

-- Write the same date and time using each of the above formats.
for row, date_format_str in ipairs(date_formats) do

  -- Create a format for the date or time.
  local date_format = workbook:add_format({num_format = date_format_str,
                                           align = "left"})

  -- Write the same date using different formats.
  worksheet:write_date_string(row, 0, date_string, date_format)

  -- Also write the format string for comparison.
  worksheet:write_string(row, 1, date_format_str)

end

workbook:close()
