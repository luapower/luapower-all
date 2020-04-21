----
--
-- A simple relative performance measurement utility for xlsxwriter.lua.
--
-- It is used to compare the memory use and speed difference when using
-- "constant_memory" mode.
--
-- Usage:
--       lua perf_tester.lua [row_max] [constant_memory] [measure_memory]
--
--        Where row_max is an integer, and the other options are 1 or 0.
--
-- Copyright 2014-2015, John McNamara, jmcnamara@cpan.org
--

local Workbook = require "xlsxwriter.workbook"

local col_max         = 50
local row_max         = arg[1] or 1000
local constant_memory = arg[2] or false
local measure_memory  = arg[3] or true
local total_size      = 0

-- The row number is divided between the string and number data.
row_max = tonumber(row_max) / 2

-- Convert the other commandline args.
if constant_memory and tonumber(constant_memory) == 0 then
  constant_memory = false
end

if measure_memory and tonumber(measure_memory) == 0 then
  measure_memory = false
end

-- Start timing after everything is loaded.
local start_time = os.clock()

-- Memory calculation and enforced garbage collection add a little overhead.
-- If required we can omit it from the timing.
if measure_memory then
  collectgarbage()
  total_size = collectgarbage("count")
end

--
-- Create a worksheet with strings and numbers.
--
local workbook  = Workbook:new("perf_lua.xlsx",
                               {constant_memory = constant_memory})
local worksheet = workbook:add_worksheet()

worksheet:set_column(0, col_max, 18)

-- Write the data in row order for constant_memory mode.
for row = 0, row_max -1 do

  -- Use unique strings since that has the highest overhead.
  for col = 0, col_max -1 do
    worksheet:write_string(row * 2, col,
                           string.format("Row: %d Col: %d", row, col))
  end

  for col = 0, col_max - 1 do
    worksheet:write_number(row * 2 + 1, col, row + col)
  end
end

-- Get total memory size before closing the workbook.
if measure_memory then
  collectgarbage()
  total_size = collectgarbage("count") - total_size
end

workbook:close()


-- Get the elapsed time.
local elapsed = os.clock() - start_time

-- Print a simple CSV output for reporting.
print(string.format("%6d, %3d, %6.2f, %d",
                    row_max * 2, col_max, elapsed, total_size * 1024))
