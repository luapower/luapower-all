
## Features

* virtual: instant rendering, scrolling and sorting of up to 100K rows.
	* acceptably fast with millions of rows.

* vertical and horizontal row/column layout.
	* can switch between the two modes anytime without recreating the grid.

* tree-list.
	* automatic: just say which columns in the model are the id and parent_id.
	* TODO: multi-state checkboxes.

* column reordering with drag & drop.
	* shows the actual column with all the cells while dragging.
	* animated placement.

* row reordering with drag & drop
	* shows the actual row being dragged, not just an icon.
	* animated placement.
	* updates an index column in the model.
	* can move a contiguous multiple selection of rows too.
	* for a tree-list, it can move rows to a different parent too.
		* moving to a different parent can be disallowed.

* column horizontal alignment.

* column sorting.
	* instant for 100K rows.
	* multi-column sorting (press shift)
	* implicit grouping of special cells.
		* invalid cells come first
		* modified & unsaved cells come first
		* nulls come first
		* NaNs come first
	* custom comparators provided by the dataset

* column resizing by drag & drop.
	* respect field's min. width.
	* respect field's max. width.
	* shows guide while dragging for auto-width grids.

* visible columns subset list.
	* respect field's hidden flag.
	* hide/show fields via context-menu.

* cell-level navigation.
	* skip-over read-only fields.
	* skip-over read-only rows.
	* customizable keyboard navigation.
		* how many rows to move on page-down/page-up
		* how to advance on enter: false|'next_row'|'next_cell'
		* jump row on horiz. navigation limits

* inline cell editing.
	* customizable editing & saving behavior.
		* jump to next/prev cell on caret limits.
		* re-enter edit mode after navigating.
		* save cell on input, edit-mode exit.
		* save row on input, edit-mode exit, row exit, manual.
		* prevent exiting edit mode on validation errors.
		* prevent changing row on validation errors.
	* custom editors.
		* drop-down.
		* check-box.
	* enter nulls with shift-delete.
	* show validation errors above/below the cell/row.
	* mark invalid cells & rows.
	* mark modified cells.
	* mark new rows.
	* mark/disable rows that are being saved.

* quick search.
	* TODO

* custom filters.
	* instant for 100K rows.
	* per-column checklist filters.
	* TODO: expression-tree editor.

* save/recall grid states.
	* TODO: filter & sort state
	* TODO: tree state: collapsed nodes
	* TODO: navigation state: focus, selection and scroll state

