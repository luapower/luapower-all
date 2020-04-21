
## Features

* virtual: instant rendering, scrolling and sorting of up to 100K rows.
	* acceptably fast with millions of rows.

* column horizontal alignment

* column sorting
	* multi-column sorting (press shift)
	* right-click to reset sorting
	* implicit grouping of special cells
		* invalid cells come first
		* modified & unsaved cells come first
		* nulls come first
		* NaNs come first
	* custom comparators provided by the dataset

* column resizing
	* respect field's min. width
	* respect field's max. width

* column reordering
	TODO

* visible columns subset list
	* respect field's hidden flag
	* TODO: select visible fields from a list

* auto-scrolling (horizontal & vertical)

* cell-level navigation
	* skip-over read-only fields
	* skip-over read-only rows
	* customizable keyboard navigation
		* how many rows to move on page-down/page-up
		* how to advance on enter: false|'next_row'|'next_cell'
		* jump row on horiz. navigation limits

* cell editing
	* customizable editing & saving behavior
		* jump to next/prev cell on caret limits
		* re-enter edit mode after navigating
		* save cell on input, edit-mode exit
		* save row on input, edit-mode exit, row exit, manual
		* prevent exiting edit mode on validation errors
		* prevent changing row on validation errors
	* custom editors
		* drop-down
		* check-box
	* enter nulls with shift-delete
	* show validation errors above/below the cell/row
	* mark invalid cells & rows
	* mark modified cells
	* mark new rows
	* mark/disable rows that are being saved

* geometry control outside css
	* fixed grid width & height
	* fixed row height
	* fixed row border height

* tree-list grouping via id/parent_id column pair
	* TODO
	* multi-state checkboxes

* quick search
	* TODO

* custom filters
	* expression-tree editor

* save/recall grid states
	* filter & sort state
	* tree state: collapsed nodes
	* navigation state: focus, selection and scroll state

