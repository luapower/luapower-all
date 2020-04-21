----
--
-- Example of how to set Excel worksheet tab colours using
-- the Xlsxwriter.lua module.
--
-- Copyright 2014-2015, John McNamara, jmcnamara@cpan.org
--

local Workbook = require "xlsxwriter.workbook"

local workbook = Workbook:new("tab_colors.xlsx")

-- Set up some worksheets.
local worksheet1 = workbook:add_worksheet()
local worksheet2 = workbook:add_worksheet()
local worksheet3 = workbook:add_worksheet()
local worksheet4 = workbook:add_worksheet()

-- Set tab colours, worksheet4 will have the default colour.
worksheet1:set_tab_color("red")
worksheet2:set_tab_color("green")
worksheet3:set_tab_color("#FF9900")

workbook:close()
