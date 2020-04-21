Working with Formats {#working_with_formats}
====================

The methods and properties used to add formatting to a cell are shown in
`format`{.interpreted-text role="ref"}. This section provides some
additional information about working with formats.

Creating and using a Format object
----------------------------------

Cell formatting is defined through a
`Format object <format>`{.interpreted-text role="ref"}. Format objects
are created by calling the workbook `add_format()` method as follows:

    format1 = workbook:add_format()      -- Set properties later.
    format2 = workbook:add_format(props) -- Set properties at creation.

Once a Format object has been constructed and its properties have been
set it can be passed as an argument to the worksheet `write` methods as
follows:

    worksheet:write       (0, 0, "Foo", format)
    worksheet:write_string(1, 0, "Bar", format)
    worksheet:write_number(2, 0, 3,     format)
    worksheet:write_blank (3, 0, "",    format)

Formats can also be passed to the worksheet `set_row()` and
`set_column()` methods to define the default formatting properties for a
row or column:

    worksheet:set_row(0, 18, format)
    worksheet:set_column("A:D", 20, format)

Format methods and Format properties
------------------------------------

The following table shows the Excel format categories, the formatting
properties that can be applied and the equivalent object method:

  --------------------------------------------------------------------------------------------
  Category     Description       Property           Method Name
  ------------ ----------------- ------------------ ------------------------------------------
  Font         Font type         `font_name`        `set_font_name()`{.interpreted-text
                                                    role="func"}

               Font size         `font_size`        `set_font_size()`{.interpreted-text
                                                    role="func"}

               Font color        `font_color`       `set_font_color()`{.interpreted-text
                                                    role="func"}

               Bold              `bold`             `set_bold()`{.interpreted-text
                                                    role="func"}

               Italic            `italic`           `set_italic()`{.interpreted-text
                                                    role="func"}

               Underline         `underline`        `set_underline()`{.interpreted-text
                                                    role="func"}

               Strikeout         `font_strikeout`   `set_font_strikeout()`{.interpreted-text
                                                    role="func"}

               Super/Subscript   `font_script`      `set_font_script()`{.interpreted-text
                                                    role="func"}

  Number       Numeric format    `num_format`       `set_num_format()`{.interpreted-text
                                                    role="func"}

  Protection   Lock cells        `locked`           `set_locked()`{.interpreted-text
                                                    role="func"}

               Hide formulas     `hidden`           `set_hidden()`{.interpreted-text
                                                    role="func"}

  Alignment    Horizontal align  `align`            `set_align()`{.interpreted-text
                                                    role="func"}

               Vertical align    `valign`           `set_align()`{.interpreted-text
                                                    role="func"}

               Rotation          `rotation`         `set_rotation()`{.interpreted-text
                                                    role="func"}

               Text wrap         `text_wrap`        `set_text_wrap()`{.interpreted-text
                                                    role="func"}

               Justify last      `text_justlast`    `set_text_justlast()`{.interpreted-text
                                                    role="func"}

               Center across     `center_across`    `set_center_across()`{.interpreted-text
                                                    role="func"}

               Indentation       `indent`           `set_indent()`{.interpreted-text
                                                    role="func"}

               Shrink to fit     `shrink`           `set_shrink()`{.interpreted-text
                                                    role="func"}

  Pattern      Cell pattern      `pattern`          `set_pattern()`{.interpreted-text
                                                    role="func"}

               Background color  `bg_color`         `set_bg_color()`{.interpreted-text
                                                    role="func"}

               Foreground color  `fg_color`         `set_fg_color()`{.interpreted-text
                                                    role="func"}

  Border       Cell border       `border`           `set_border()`{.interpreted-text
                                                    role="func"}

               Bottom border     `bottom`           `set_bottom()`{.interpreted-text
                                                    role="func"}

               Top border        `top`              `set_top()`{.interpreted-text role="func"}

               Left border       `left`             `set_left()`{.interpreted-text
                                                    role="func"}

               Right border      `right`            `set_right()`{.interpreted-text
                                                    role="func"}

               Border color      `border_color`     `set_border_color()`{.interpreted-text
                                                    role="func"}

               Bottom color      `bottom_color`     `set_bottom_color()`{.interpreted-text
                                                    role="func"}

               Top color         `top_color`        `set_top_color()`{.interpreted-text
                                                    role="func"}

               Left color        `left_color`       `set_left_color()`{.interpreted-text
                                                    role="func"}

               Right color       `right_color`      `set_right_color()`{.interpreted-text
                                                    role="func"}
  --------------------------------------------------------------------------------------------

There are two ways of setting Format properties: by using the object
interface or by setting the property as a table of key/value pairs in
the constructor. For example, a typical use of the object interface
would be as follows:

    format = workbook:add_format()
    format:set_bold()
    format:set_font_color("red")

By comparison the properties can be set by passing a table of properties
to the [add\_format()]{.title-ref} constructor:

    format = workbook:add_format({bold = true, font_color = "red"})

The object method interface is mainly provided for backward
compatibility. The key/value interface has proved to be more flexible in
real world programs and is the recommended method for setting format
properties.

It is also possible, as with any Lua function that takes a table as its
only parameter to use the following shorthand syntax:

> format = workbook:add\_format{bold = true, font\_color = \"red\"}

Format Colors
-------------

Format property colors are specified using a Html sytle `#RRGGBB` value
or a imited number of named colors:

    format1:set_font_color("#FF0000")
    format2:set_font_color("red")

See `colors`{.interpreted-text role="ref"} for more details.

Format Defaults
---------------

The default Excel 2007+ cell format is Calibri 11 with all other
properties off.

In general a format method call without an argument will turn a property
on, for example:

    format = workbook:add_format()

    format:set_bold()  -- Turns bold on.

Modifying Formats
-----------------

Each unique cell format in an `xlsxwriter` spreadsheet must have a
corresponding Format object. It isn\'t possible to use a Format with a
`write()` method and then redefine it for use at a later stage. This is
because a Format is applied to a cell not in its current state but in
its final state. Consider the following example:

    format = workbook:add_format({bold - true, font_color = "red"})
    worksheet:write("A1", "Cell A1", format)

    -- Later...
    format:set_font_color("green")
    worksheet:write("B1", "Cell B1", format)

Cell A1 is assigned a format which is initially has the font set to the
colour red. However, the colour is subsequently set to green. When Excel
displays Cell A1 it will display the final state of the Format which in
this case will be the colour green.
