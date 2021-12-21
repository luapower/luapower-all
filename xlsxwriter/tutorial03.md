Tutorial 3: Writing different types of data to the XLSX File {#tutorial3}
============================================================

In the previous section we created a simple spreadsheet with formatting
using Lua and the `xlsxwriter` module.

This time let\'s extend the data we want to write to include some dates:

    expenses = {
      {"Rent", "2013-01-13", 1000},
      {"Gas",  "2013-01-14",  100},
      {"Food", "2013-01-16",  300},
      {"Gym",  "2013-01-20",   50},
    }

The corresponding spreadsheet will look like this:

![](/files/luapower/xlsxwriter/_images/tutorial03.png)

The differences here are that we have added a Date column with
formatting and made that column a little wider to accommodate the dates.

To do this we can extend our program as follows:

::: {.only}
html

(The significant changes are shown with a red line.)
:::

``` {.lua}
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
worksheet:set_column("B:B", 15)

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
```

The main difference between this and the previous program is that we
have added a new `Format <Format>`{.interpreted-text role="ref"} object
for dates and we have additional handling for data types.

Excel treats different types of input data, such as strings and numbers,
differently although it generally does it transparently to the user.
Xlsxwriter tries to emulate this in the
`worksheet: <Worksheet>`{.interpreted-text
role="ref"}`write()`{.interpreted-text role="func"} method by mapping
Lua data types to types that Excel supports.

The `write()` method acts as a general alias for several more specific
methods:

-   `write_string()`{.interpreted-text role="func"}
-   `write_number()`{.interpreted-text role="func"}
-   `write_blank()`{.interpreted-text role="func"}
-   `write_formula()`{.interpreted-text role="func"}
-   `write_boolean()`{.interpreted-text role="func"}

In this version of our program we have used some of these explicit
`write_` methods for different types of data:

    worksheet:write_string     (row, col,     item)
    worksheet:write_date_string(row, col + 1, date, date_format)
    worksheet:write_number     (row, col + 2, cost, money)

This is mainly to show that if you need more control over the type of
data you write to a worksheet you can use the appropriate method. In
this simplified example the `write()`{.interpreted-text role="func"}
method would actually have worked just as well.

The handling of dates is also new to our program.

Dates and times in Excel are floating point numbers that have a number
format applied to display them in the correct format. Since there is no
native Lua date or time types `xlsxwriter` provides the
`write_date_string()`{.interpreted-text role="func"} and
`write_date_time()`{.interpreted-text role="func"} methods to convert
dates and times into Excel date and time numbers.

In the example above we use `write_date_string()`{.interpreted-text
role="func"} but we also need to add the number format to ensure that
Excel displays it as as date:

    ...

    local date_format = workbook:add_format({num_format = "mmmm d yyyy"})
    ...

    for _, expense in ipairs(expenses) do
      ...
      worksheet:write_date_string(row, col + 1, date, date_format)
      ...
    end

Date handling is explained in more detail in
`working_with_dates_and_time`{.interpreted-text role="ref"}.

The last addition to our program is the `set_column`{.interpreted-text
role="func"} method to adjust the width of column \"B\" so that the
dates are more clearly visible:

    -- Adjust the column width.
    worksheet:set_column("B:B", 15)

That completes the tutorial section.

In the next sections we will look at the API in more detail starting
with `workbook`{.interpreted-text role="ref"}.
