----
--
-- A simple Unicode UTF-8 example using the xlsxwriter.lua module.
--
-- Note: The source file must be UTF-8 encoded.
--
-- Copyright 2014-2015, John McNamara, jmcnamara@cpan.org
--

local Workbook = require "xlsxwriter.workbook"

local workbook  = Workbook:new("utf8.xlsx")
local worksheet = workbook:add_worksheet()

worksheet:write("B3", "Это фраза на русском!")

workbook:close()
