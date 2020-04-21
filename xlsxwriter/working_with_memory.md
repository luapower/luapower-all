Working with Memory and Performance {#memory_perf}
===================================

By default `xlsxwriter` holds all cell data in memory. This is to allow
future features where formatting is applied separately from the data.

The effect of this is that for large files `xlsxwriter` can consume a
lot of memory and it is even possible to run out of memory.

Fortunately, this memory usage can be reduced almost completely by
setting the `Workbook:new() <constructor>`{.interpreted-text role="ref"}
`'constant_memory'` property:

    workbook = Workbook:new(filename, {constant_memory = true})

The optimisation works by flushing each row after a subsequent row is
written. In this way the largest amount of data held in memory for a
worksheet is the amount of memory required to hold a single row of data.

Since each new row flushes the previous row, data must be written in
sequential row order when `'constant_memory'` mode is on:

    -- With 'constant_memory' you must write data in row column order.
    for row = 0, row_max do
      for col = 0, col_max do
        worksheet:write(row, col, some_data)
      end
    end

    -- With 'constant_memory' the following would only write the first column.
    for col = 0, col_max do  -- !!
      for row = 0, row_max do
        worksheet:write(row, col, some_data)
      end
    end

Another optimisation that is used to reduce memory usage is that cell
strings aren\'t stored in an Excel structure call \"shared strings\" and
instead are written \"in-line\". This is a documented Excel feature that
is supported by most spreadsheet applications. One known exception is
Apple Numbers for Mac where the string data isn\'t displayed.

The trade-off when using `'constant_memory'` mode is that you won\'t be
able to take advantage of any features that manipulate cell data after
it is written. Currently there aren\'t any such features.

For larger files `'constant_memory'` mode also gives an increase in
execution speed, see below.

Performance Figures
-------------------

The performance figures below show execution time and memory usage for
worksheets of size `N` rows x 50 columns with a 50/50 mixture of strings
and numbers. The figures are taken from an arbitrary, mid-range,
machine. Specific figures will vary from machine to machine but the
trends should be the same.

Xlsxwriter in normal operation mode: the execution time and memory usage
increase more of less linearly with the number of rows:

+-------+---------+----------+----------------+
| Rows  | Columns | Time (s) | Memory (bytes) |
+=======+=========+==========+================+
| > 200 | 50      | > 0.20   | 2071819        |
+-------+---------+----------+----------------+
| > 400 | 50      | > 0.40   | 4149803        |
+-------+---------+----------+----------------+
| > 800 | 50      | > 0.86   | 8305771        |
+-------+---------+----------+----------------+
| >     | 50      | > 1.87   | 16617707       |
|  1600 |         |          |                |
+-------+---------+----------+----------------+
| >     | 50      | > 3.84   | 33271579       |
|  3200 |         |          |                |
+-------+---------+----------+----------------+
| >     | 50      | > 8.02   | 66599323       |
|  6400 |         |          |                |
+-------+---------+----------+----------------+
| 12800 | 50      | 16.54    | 133254811      |
+-------+---------+----------+----------------+

Xlsxwriter in `constant_memory` mode: the execution time still increases
linearly with the number of rows but the memory usage remains small and
mainly constant:

+-------+---------+----------+----------------+
| Rows  | Columns | Time (s) | Memory (bytes) |
+=======+=========+==========+================+
| > 200 | 50      | > 0.18   | 41119          |
+-------+---------+----------+----------------+
| > 400 | 50      | > 0.36   | 24735          |
+-------+---------+----------+----------------+
| > 800 | 50      | > 0.69   | 24735          |
+-------+---------+----------+----------------+
| >     | 50      | > 1.41   | 24735          |
|  1600 |         |          |                |
+-------+---------+----------+----------------+
| >     | 50      | > 2.83   | 41119          |
|  3200 |         |          |                |
+-------+---------+----------+----------------+
| >     | 50      | > 5.83   | 41119          |
|  6400 |         |          |                |
+-------+---------+----------+----------------+
| 12800 | 50      | 11.29    | 24735          |
+-------+---------+----------+----------------+

These figures were generated using the `perf_tester.lua` program in the
`examples` directory of the xlsxwriter repo.

Note, there will be further optimisation in both modes in later
releases.
