
## Features

* snapping
	* snap to line.
	* snap to face.
	* snap to line end-points and mid-point
	* snap to axes from last point
	* choose a ref point and snap to axes originating at the ref point
	* TODO: snap to multiple automatic ref-points (coplanar, etc.)
	* TODO: choose a ref line and snap to perpendicular and paralel to that line.
	* TODO: snap to perpendicular to the starting line.
	* TODO: snap free-moving line to existing points.
	* TODO: snap free-moving line to existing intersecting or parallel lines.
	* TODO: merge overlapping lines.
	* snap to ground plane.
	* snap to most-in-front vertical plane.

* line tool
	* auto-cut lines.
	* TODO: auto-cut faces.

* selection & removal
	* modes: replace, toggle, add, remove.
	* double click to select adjacent faces or lines.
	* triple-click to select the entire model.
		TODO: triple-click should only select connected geometry.
	* TODO: rectangle selection: intersecting and bounding modes.
	* remove selected lines and faces.
		* auto-remove faces that are no longer connected.
		* TODO: merge coplanar faces when separating edges are removed.

* push-pull tool
	* adjust geometry to make pulling available.
	* snap to touching geometry along the extrusion axis.
	* TODO: merge with intersecting faces at the end of pulling and create holes.
	* TODO: intersect side faces and lines with existing existing geometery at the end of pulling.
	* TODO: limit movement to non-intersecting faces.

* move/rotate tool
	* TODO: split faces where their points are no longer coplanar.

* protractor tool

* rectangle tool

* eraser tool

* orbit tool
	* wheel zoom tracks mouse

* components
	* make/break component
	* enter/exit component edit mode
	* set local axes
	* highlight all instances

* set global axes

* layers

* scenes
	* scene transitions

* shadows
	* latitude-based with date/time controls.

* texturing
	* paint tool
	* eyedropper tool
	* move/rotate/scale/shear texture with snapping
	* bump mapping
	* opacity

* rendering
	* thick non-edge lines.
	* TODO: thick object outline.

