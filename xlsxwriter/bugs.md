### Content is Unreadable. Open and Repair

Very, very occasionally you may see an Excel warning when opening an
`xlsxwriter` file like:

> Excel could not open file.xlsx because some content is unreadable. Do
> you want to open and repair this workbook.

This ominous sounding message is Excel\'s default warning for any
validation error in the XML used for the components of the XLSX file.

If you encounter an issue like this you should open an issue on GitHub
with a program to replicate the issue (see below) or send one of the
failing output files to the `author`{.interpreted-text role="ref"}.

### Formulas displayed as `#NAME?` until edited

Excel 2010 and 2013 added functions which weren\'t defined in the
original file specification. These functions are referred to as *future*
functions. Examples of these functions are `ACOT`, `CHISQ.DIST.RT` ,
`CONFIDENCE.NORM`, `STDEV.P`, `STDEV.S` and `WORKDAY.INTL`. The full
list is given in the [MS XLSX extensions documentation on future
functions](http://msdn.microsoft.com/en-us/library/dd907480%28v=office.12%29.aspx).

When written using `write_formula()` these functions need to be fully
qualified with the `_xlfn.` prefix as they are shown in the MS XLSX
documentation link above. For example:

    worksheet:write_formula('A1', '=_xlfn.STDEV.S(B1:B10)')

### Formula results displaying as zero in non-Excel applications

Due to wide range of possible formulas and interdependencies between
them, `xlsxwriter` doesn\'t, and realistically cannot, calculate the
result of a formula when it is written to an XLSX file. Instead, it
stores the value 0 as the formula result. It then sets a global flag in
the XLSX file to say that all formulas and functions should be
recalculated when the file is opened.

This is the method recommended in the Excel documentation and in general
it works fine with spreadsheet applications. However, applications that
don\'t have a facility to calculate formulas, such as Excel Viewer, or
several mobile applications, will only display the 0 results.

If required, it is also possible to specify the calculated result of the
formula using the optional `value` parameter in
`write_formula()`{.interpreted-text role="func"}:

    worksheet:write_formula('A1', '=2+2', num_format, 4)

### Strings aren\'t displayed in Apple Numbers in \'constant\_memory\' mode

In `Workbook`{.interpreted-text role="func"} `'constant_memory'` mode
`xlsxwriter` uses an optimisation where cell strings aren\'t stored in
an Excel structure call \"shared strings\" and instead are written
\"in-line\".

This is a documented Excel feature that is supported by most spreadsheet
applications. One known exception is Apple Numbers for Mac where the
string data isn\'t displayed.

### Images not displayed correctly in Excel 2001 for Mac and non-Excel applications

Images inserted into worksheets via `insert_image`{.interpreted-text
role="func"} may not display correctly in Excel 2011 for Mac and
non-Excel applications such as OpenOffice and LibreOffice. Specifically
the images may looked stretched or squashed.

This is not specifically an `xlsxwriter` issue. It also occurs with
files created in Excel 2007 and Excel 2010.

