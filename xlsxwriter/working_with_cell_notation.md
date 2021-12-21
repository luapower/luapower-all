Working with Cell Notation {#cell_notation}
==========================

Xlsxwriter.lua supports two forms of notation to designate the position
of cells: **Row-column** notation and **A1** notation.

Row-column notation uses a zero based index for both row and column
while A1 notation uses the standard Excel alphanumeric sequence of
column letter and 1-based row. For example:

    (0, 0)     -- Row-column notation.
    ("A1")     -- The same cell in A1 notation.

    (6, 2)     -- Row-column notation.
    ("C7")     -- The same cell in A1 notation.

Row-column notation is useful if you are referring to cells
programmatically:

    for row = 0, 5 do
        worksheet:write(row, 0, "Hello")
    end

A1 notation is useful for setting up a worksheet manually and for
working with formulas:

    worksheet:write("H1", 200)
    worksheet:write("H2", "=H1+1")

In general when using the `xlsxwriter` module you can use A1 notation
anywhere you can use row-column notation.

::: {.note}
::: {.title}
Note
:::

In Excel it is also possible to use R1C1 notation. This is not supported
by `xlsxwriter`.
:::

Relative and Absolute cell references {#abs_reference}
-------------------------------------

When dealing with Excel cell references it is important to distinguish
between relative and absolute cell references in Excel.

**Relative** cell references change when they are copied while
**Absolute** references maintain fixed row and/or column references. In
Excel absolute references are prefixed by the dollar symbol as shown
below:

    A1   -- Column and row are relative.
    $A1  -- Column is absolute and row is relative.
    A$1  -- Column is relative and row is absolute.
    $A$1 -- Column and row are absolute.

See the Microsoft Office documentation for [more information on relative
and absolute
references](http://office.microsoft.com/en-001/excel-help/switch-between-relative-absolute-and-mixed-references-HP010342940.aspx).

Cell Utility Functions {#cell_utility}
======================

The `xlsxwriter.utility` module contains several helper functions for
dealing with A1 notation. These functions can be imported and used as
follows:

    local Utility = require "xlsxwriter.utility"

    cell = Utilty.rowcol_to_cell(1, 2) --> C2

The available functions are shown below.

rowcol\_to\_cell()
------------------

::: {.function}
rowcol\_to\_cell(row, col)

Convert a zero indexed row and column cell reference to a A1 style
string.

param row

:   The cell row.

param col

:   The cell column.

rtype

:   A1 style string.
:::

The `rowcol_to_cell()` function converts a zero indexed row and column
cell values to an `A1` style string:

    cell = Utilty.rowcol_to_cell(0, 0) --> A1
    cell = Utilty.rowcol_to_cell(0, 1) --> B1
    cell = Utilty.rowcol_to_cell(1, 0) --> A2

rowcol\_to\_cell\_abs()
-----------------------

::: {.function}
rowcol\_to\_cell\_abs(row, col\[, row\_abs, col\_abs\])

Convert a zero indexed row and column cell reference to a A1 style
string.

param row

:   The cell row.

param col

:   The cell column.

param row\_abs

:   Optional flag to make the row absolute.

param col\_abs

:   Optional flag to make the column absolute.

rtype

:   A1 style string.
:::

The `rowcol_to_cell_abs()` function is like the `rowcol_to_cell_abs()`
function but the optional parameters `row_abs` and `col_abs` can be used
to indicate that the row or column is absolute:

    str = Utilty.rowcol_to_cell_abs(0, 0, false, true) --> $A1
    str = Utilty.rowcol_to_cell_abs(0, 0, true       ) --> A$1
    str = Utilty.rowcol_to_cell_abs(0, 0, true,  true) --> $A$1

cell\_to\_rowcol()
------------------

::: {.function}
cell\_to\_rowcol(cell\_str)

Convert a cell reference in A1 notation to a zero indexed row and
column.

param cell\_str

:   A1 style string, absolute or relative.

rtype

:   row, col.
:::

The `cell_to_rowcol()` function converts an Excel cell reference in `A1`
notation to a zero based row and column. The function will also handle
Excel\"s absolute cell notation:

    row, col = Utilty.cell_to_rowcol("A1")   --> (0, 0)
    row, col = Utilty.cell_to_rowcol("B1")   --> (0, 1)
    row, col = Utilty.cell_to_rowcol("C2")   --> (1, 2)
    row, col = Utilty.cell_to_rowcol("$C2")  --> (1, 2)
    row, col = Utilty.cell_to_rowcol("C$2")  --> (1, 2)
    row, col = Utilty.cell_to_rowcol("$C$2") --> (1, 2)

col\_to\_name()
---------------

::: {.function}
col\_to\_name(col\[, col\_abs\])

Convert a zero indexed column cell reference to a string.

param col

:   The cell column.

param col\_abs

:   Optional flag to make the column absolute.

rtype

:   Column style string.
:::

The `col_to_name()` converts a zero based column reference to a string:

    column = Utilty.col_to_name(0)   --> A
    column = Utilty.col_to_name(1)   --> B
    column = Utilty.col_to_name(702) --> AAA

The optional parameter `col_abs` can be used to indicate if the column
is absolute:

    column = Utilty.col_to_name(0, false) --> A
    column = Utilty.col_to_name(0, true)  --> $A
    column = Utilty.col_to_name(1, true)  --> $B

range()
-------

::: {.function}
range(first\_row, first\_col, last\_row, last\_col)

Converts zero indexed row and column cell references to a A1:B1 range
string.

param first\_row

:   The first cell row.

param first\_col

:   The first cell column.

param last\_row

:   The last cell row.

param last\_col

:   The last cell column.

rtype

:   A1:B1 style range string.
:::

The `range()` function converts zero based row and column cell
references to an `A1:B1` style range string:

    cell_range = Utilty.range(0, 0, 9, 0) --> A1:A10
    cell_range = Utilty.range(1, 2, 8, 2) --> C2:C9
    cell_range = Utilty.range(0, 0, 3, 4) --> A1:E4

range\_abs()
------------

The `range_abs()` function converts zero based row and column cell
references to an absolute `$A$1:$B$1` style range string:

    cell_range = Utilty.range_abs(0, 0, 9, 0) --> $A$1:$A$10
    cell_range = Utilty.range_abs(1, 2, 8, 2) --> $C$2:$C$9
    cell_range = Utilty.range_abs(0, 0, 3, 4) --> $A$1:$E$4
