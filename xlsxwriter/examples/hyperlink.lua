----
--
-- Example of how to use the xlsxwriter.lua module to write hyperlinks.
--
-- Copyright 2014-2015, John McNamara, jmcnamara@cpan.org
--

local Workbook = require "xlsxwriter.workbook"

local workbook  = Workbook:new("hyperlink.xlsx")
local worksheet = workbook:add_worksheet("Hyperlinks")

-- Format the first column
worksheet:set_column('A:A', 30)

-- Add the standard url link format.
local url_format = workbook:add_format({
    font_color = 'blue',
    underline  = 1
})

-- Add a sample alternative link format.
local red_format = workbook:add_format({
    font_color = 'red',
    bold       = 1,
    underline  = 1,
    font_size  = 12,
})

-- Add an alternate description string to the URL.
local alt_string = 'Lua home'

-- Add a "tool tip" to the URL.
local tip_string = 'Get the latest Lua news here.'

-- Write some hyperlinks
worksheet:write_url('A1', 'http://www.lua.org/', url_format)
worksheet:write_url('A3', 'http://www.lua.org/', url_format, alt_string)
worksheet:write_url('A5', 'http://www.lua.org/', url_format, alt_string, tip_string)
worksheet:write_url('A7', 'http://www.lua.org/', red_format)
worksheet:write_url('A9', 'mailto:jmcnamaracpan.org', url_format, 'Mail me')

-- Write a URL that isn't a hyperlink
worksheet:write_string('A11', 'http://www.lua.org/')

workbook:close()
