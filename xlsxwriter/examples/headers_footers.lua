----
--
-- This program shows several examples of how to set up headers and
-- footers with xlsxwriter.
--
-- The control characters used in the header/footer strings are:
--
--     Control             Category            Description
--     =======             ========            ===========
--     &L                  Justification       Left
--     &C                                      Center
--     &R                                      Right
--
--     &P                  Information         Page number
--     &N                                      Total number of pages
--     &D                                      Date
--     &T                                      Time
--     &F                                      File name
--     &A                                      Worksheet name
--
--     &fontsize           Font                Font size
--     &"font,style"                           Font name and style
--     &U                                      Single underline
--     &E                                      Double underline
--     &S                                      Strikethrough
--     &X                                      Superscript
--     &Y                                      Subscript
--
--     &&                  Miscellaneous       Literal ampersand &
--
-- See the main XlsxWriter documentation for more information.
--
-- Copyright 2014-2015, John McNamara, jmcnamara@cpan.org
--

local Workbook = require "xlsxwriter.workbook"

local workbook  = Workbook:new("headers_footers.xlsx")

----
--
-- A simple example to start
--
local worksheet1 = workbook:add_worksheet("Simple")
local header1    = "&CHere is some centred text."
local footer1    = "&LHere is some left aligned text."

worksheet1:set_header(header1)
worksheet1:set_footer(footer1)
worksheet1:set_page_view()

worksheet1:set_column("A:A", 50)
worksheet1:write("A1", "Headers and footers added.")

----
--
-- This is an example of some of the header/footer variables.
--
local worksheet2 = workbook:add_worksheet("Variables")
local header2    = "&LPage &P of &N" .. "&CFilename: &F" .. "&RSheetname: &A"
local footer2    = "&LCurrent date: &D" .. "&RCurrent time: &T"

worksheet2:set_header(header2)
worksheet2:set_footer(footer2)
worksheet2:set_page_view()

worksheet2:set_column("A:A", 50)
worksheet2:write("A1", "Headers and footers with variable parameters.")
worksheet2:write("A20", "Page break inserted here.")
worksheet2:write("A21", "Next sheet")
worksheet2:set_h_pagebreaks({20})

----
--
-- This example shows how to use more than one font
--
local worksheet3 = workbook:add_worksheet("Mixed fonts")
local header3    = '&C&"Courier New,Bold"Hello &"Arial,Italic"World'
local footer3    = '&C&"Symbol"e&"Arial" = mc&X2'

worksheet3:set_header(header3)
worksheet3:set_footer(footer3)
worksheet3:set_page_view()

worksheet3:set_column("A:A", 50)
worksheet3:write("A1", "Headers and footers with mixed fonts.")

----
--
-- Example of line wrapping
--
local worksheet4 = workbook:add_worksheet("Word wrap")
local header4    = "&CHeading 1\nHeading 2"

worksheet4:set_header(header4)
worksheet4:set_page_view()

worksheet4:set_column("A:A", 50)
worksheet4:write("A1", "Header with wrapped text.")

----
--
-- Example of inserting a literal ampersand &
--
local worksheet5 = workbook:add_worksheet("Ampersand")
local header5    = "&CCuriouser && Curiouser - Attorneys at Law"

worksheet5:set_header(header5)
worksheet5:set_page_view()

worksheet5:set_column("A:A", 50)
worksheet5:write("A1", "Header with an ampersand.")

workbook:close()
