----
--
-- A hello world spreadsheet using the xlsxwriter.lua module.
--
-- Copyright 2014-2015, John McNamara, jmcnamara@cpan.org
--

local Workbook = require "xlsxwriter.workbook"

local workbook  = Workbook:new("hello_world.xlsx")
local worksheet = workbook:add_worksheet()

worksheet:write("A1", "Hello world")

workbook:close()
