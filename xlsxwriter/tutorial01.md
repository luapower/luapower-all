Tutorial 1: Create a simple XLSX file {#tutorial1}
=====================================

Let\'s start by creating a simple spreadsheet using Lua and the
`xlsxwriter` module.

Say that we have some data on monthly outgoings that we want to convert
into an Excel XLSX file:

    expenses = {
      {"Rent", 1000},
      {"Gas",   100},
      {"Food",  300},
      {"Gym",    50},
    }

To do that we can start with a small program like the following:

``` {.lua}
local Workbook = require "xlsxwriter.workbook"


-- Create a workbook and add a worksheet.
local workbook  = Workbook:new("Expensese01.xlsx")
local worksheet = workbook:add_worksheet()

-- Some data we want to write to the worksheet.
local expenses = {
  {"Rent", 1000},
  {"Gas",   100},
  {"Food",  300},
  {"Gym",    50},
}

-- Start from the first cell. Rows and columns are zero indexed.
local row = 0
local col = 0

-- Iterate over the data and write it out element by element.
for _, expense in ipairs(expenses) do
  local item, cost = unpack(expense)
  worksheet:write(row, col,     item)
  worksheet:write(row, col + 1, cost)
  row = row + 1
end

-- Write a total using a formula.
worksheet:write(row, 0, "Total")
worksheet:write(row, 1, "=SUM(B1:B4)")

workbook:close()
```

If we run this program we should get a spreadsheet that looks like this:

![](/files/luapower/xlsxwriter/_images/tutorial01.png)

This is a simple example but the steps involved are representative of
all programs that use xlsxwriter, so let\'s break it down into separate
parts.

The first step is to import the module:

    local Workbook = require "xlsxwriter.workbook"

The next step is to create a new workbook object using the
`Workbook:new()` constructor.

`Workbook:new() <constructor>`{.interpreted-text role="ref"} takes one,
non-optional, argument which is the filename that we want to create:

    local workbook = Workbook:new("Expensese01.xlsx")

The workbook object is then used to add a new worksheet via the
`add_worksheet`{.interpreted-text role="func"} method:

    local worksheet = workbook:add_worksheet()

By default worksheet names in the spreadsheet will be
[Sheet1]{.title-ref}, [Sheet2]{.title-ref} etc., but we can also specify
a name:

    worksheet1 = workbook:add_worksheet()        -- Defaults to Sheet1.
    worksheet2 = workbook:add_worksheet("Data")  -- Data.
    worksheet3 = workbook:add_worksheet()        -- Defaults to Sheet3.

We can then use the worksheet object to write data via the
`write`{.interpreted-text role="func"} method:

    worksheet:write(row, col, some_data)

::: {.note}
::: {.title}
Note
:::

Throughout the `xlsxwriter` API *rows* and *columns* are zero indexed.
Thus, the first cell in a worksheet, `A1`, is `(0, 0)`.
:::

So in our example we iterate over our data and write it out as follows:

    -- Iterate over the data and write it out element by element.
    for _, expense in ipairs(expenses) do
      local item, cost = unpack(expense)
      worksheet:write(row, col,     item)
      worksheet:write(row, col + 1, cost)
      row = row + 1
    end

We then add a formula to calculate the total of the items in the second
column:

    worksheet:write(row, 1, "=SUM(B1:B4)")

Finally, we close the Excel file via the `close`{.interpreted-text
role="func"} method:

    workbook:close()

And that\'s it. We now have a file that can be read by Excel and other
spreadsheet applications.

In the next sections we will see how we can use the `xlsxwriter` module
to add formatting and other Excel features.
