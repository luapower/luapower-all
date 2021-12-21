The Workbook Class {#workbook}
==================

The Workbook class is the main class exposed by the `xlsxwriter` module
and it is the only class that you will need to instantiate directly.

The Workbook class represents the entire spreadsheet as you see it in
Excel and internally it represents the Excel file as it is written on
disk.

Constructor
-----------

::: {.function}
Workbook:new(filename\[,options\])

Create a new `xlsxwriter` Workbook object.

param filename

:   The name of the new Excel file to create.

param options

:   Optional workbook parameters. See below.

rtype

:   A Workbook object.
:::

The `Workbook:new()` constructor is used to create a new Excel workbook
with a given filename:

    local Workbook = require "xlsxwriter.workbook"

    workbook  = Workbook:new("filename.xlsx")
    worksheet = workbook:add_worksheet()

    worksheet:write(0, 0, "Hello Excel")

    workbook:close()

![](/files/luapower/xlsxwriter/_images/workbook01.png)

The constructor options are:

-   **constant\_memory**: Reduces the amount of data stored in memory so
    that large files can be written efficiently:

        workbook = Workbook:new(filename, {constant_memory = true})

    Note, in this mode a row of data is written and then discarded when
    a cell in a new row is added via one of the worksheet `write_()`
    methods. Therefore, once this mode is active, data should be written
    in sequential row order.

    See `memory_perf`{.interpreted-text role="ref"} for more details.

When specifying a filename it is recommended that you use an `.xlsx`
extension or Excel will generate a warning when opening the file.

workbook:add\_worksheet()
-------------------------

::: {.function}
add\_worksheet(\[sheetname\])

Add a new worksheet to a workbook:

param sheetname

:   Optional worksheet name, defaults to Sheet1, etc.

rtype

:   A `worksheet <Worksheet>`{.interpreted-text role="ref"} object.
:::

The `add_worksheet()` method adds a new worksheet to a workbook.

At least one worksheet should be added to a new workbook. The
`Worksheet <worksheet>`{.interpreted-text role="ref"} object is used to
write data and configure a worksheet in the workbook.

The `sheetname` parameter is optional. If it is not specified the
default Excel convention will be followed, i.e. Sheet1, Sheet2, etc.:

    worksheet1 = workbook:add_worksheet()          -- Sheet1
    worksheet2 = workbook:add_worksheet("Foglio2") -- Foglio2
    worksheet3 = workbook:add_worksheet("Data")    -- Data
    worksheet4 = workbook:add_worksheet()          -- Sheet4

![image](/files/luapower/xlsxwriter/_images/workbook02.png)

The worksheet name must be a valid Excel worksheet name, i.e. it cannot
contain any of the characters `[ ] : * ? / \` and it must be less than
32 characters.

In addition, you cannot use the same, case insensitive, `sheetname` for
more than one worksheet.

workbook:add\_format()
----------------------

::: {.function}
add\_format(\[properties\])

Create a new Format object to formats cells in worksheets.

paramionary properties

:   An optional table of format properties.

rtype

:   A `Format <Format>`{.interpreted-text role="ref"} object.
:::

The `add_format()` method can be used to create new
`Format <Format>`{.interpreted-text role="ref"} objects which are used
to apply formatting to a cell. You can either define the properties at
creation time via a table of property values or later via method calls:

    format1 = workbook:add_format(props) -- Set properties at creation.
    format2 = workbook:add_format()      -- Set properties later.

See the `format`{.interpreted-text role="ref"} and
`working_with_formats`{.interpreted-text role="ref"} sections for more
details about Format properties and how to set them.

workbook:close()
----------------

::: {.function}
close()

Close the Workbook object and write the XLSX file.
:::

This should be done for every file.

> workbook:close()

Currently, there is no implicit `close()`.

workbook:set\_properties()
--------------------------

::: {.function}
set\_properties()

Set the document properties such as Title, Author etc.

param properties

:   Dictionary of document properties.
:::

The `set_properties` method can be used to set the document properties
of the Excel file created by `xlsxwriter`. These properties are visible
when you use the `Office Button -> Prepare -> Properties` option in
Excel and are also available to external applications that read or index
windows files.

The properties that can be set are:

-   `title`
-   `subject`
-   `author`
-   `manager`
-   `company`
-   `category`
-   `keywords`
-   `comments`
-   `status`

The properties are all optional and should be passed in table format as
follows:

    workbook:set_properties({
        title =    'This is an example spreadsheet',
        subject =  'With document properties',
        author =   'John McNamara',
        manager =  'Dr. Heinz Doofenshmirtz',
        company =  'of Wolves',
        category = 'Example spreadsheets',
        keywords = 'Sample, Example, Properties',
        comments = 'Created with Lua and the xlsxwriter module'})

![](/files/luapower/xlsxwriter/_images/doc_properties.png)

See also `ex_doc_properties`{.interpreted-text role="ref"}.

workbook:define\_name()
-----------------------

::: {.function}
define\_name()

Create a defined name in the workbook to use as a variable.

param name

:   The defined name.

param formula

:   The cell or range that the defined name refers to.
:::

This method is used to defined a name that can be used to represent a
value, a single cell or a range of cells in a workbook: These defined
names can then be used in formulas:

    workbook:define_name("Exchange_rate", "=0.96")
    worksheet:write("B3", "=Exchange_rate")

![](/files/luapower/xlsxwriter/_images/defined_name.png)

As in Excel a name defined like this is \"global\" to the workbook and
can be referred to from any worksheet:

    -- Global workbook name.
    workbook:define_name("Sales",         "=Sheet1!$G$1:$H$10")

It is also possible to define a local/worksheet name by prefixing it
with the sheet name using the syntax `'sheetname!definedname'`:

    -- Local worksheet name.
    workbook:define_name("Sheet2!Sales", "=Sheet2!$G$1:$G$10")

If the sheet name contains spaces or special characters you must follow
the Excel convention and enclose it in single quotes:

    workbook:define_name("'New Data'!Sales", "=Sheet2!$G$1:$G$10")

See also `ex_defined_name`{.interpreted-text role="ref"}.

workbook:worksheets()
---------------------

::: {.function}
worksheets()

Return a sequence of the worksheet objects in the workbook:

rtype

:   A sequence of `worksheet <Worksheet>`{.interpreted-text role="ref"}
    objects.
:::

The `worksheets()` method returns a table/sequence of the worksheets in
a workbook suitable for iteration with `ipairs()`. This is useful if you
want to repeat an operation on each worksheet in a workbook:

    for _, worksheet in ipairs(workbook:worksheets()) do
        worksheet:write("A1", "Hello")
    end
