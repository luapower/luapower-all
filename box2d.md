---
tagline: rectangle math
---

## `local box = require'box2d'`

Math for 2D rectangles defined as `(x, y, w, h)` where w > 0 and h > 0.

## API

-------------------------------------------------------------------- -----------------------------------------------------
**representation forms**

`box.corners(x, y, w, h) -> x1, y1, x2, y2`                          left,top and right,bottom corners

`box.rect(x1, y1, x2, y2) -> x, y, w, h`                             box given left,top and right,bottom corners

**normalization**

`box.normalize(x, y, w, h) -> x, y, w, h`                            return the same box with positive width and height

**layouting**

`box.align(w, h, halign, valign,` \                                  align a box in another box
`bx, by, bw, bh) -> x, y, w, h`

`box.vsplit(i, sh, x, y, w, h) -> x, y, w, h`                        slice a box horizontally at a certain height
																							and return the i'th box. if sh is negative,
																							slicing is done from the bottom side.

`box.hsplit(i, sw, x, y, w, h) -> x, y, w, h`                        slice a box vertically at a certain width and
																							return the i'th box. if sw is negative,
																							slicing is done from the right side.

`box.nsplit(i, n, direction, x, y, w, h) -> x, y, w, h`              slice a box in n equal slices, vertically
																							or horizontally, and return the i'th box.
																							direction = 'v' or 'h'

`box.translate(x0, y0, x, y, w, h) -> x, y, w, h`                    move a box

`box.offset(d, x, y, w, h) -> x, y, w, h`                            offset a box by d, outward if d is positive

`box.fit(w, h, bw, bh) -> w, h`                                      fit a box into another box preserving aspect ratio.
																							use align() to position the box

**hit testing**

`box.hit(x0, y0, x, y, w, h) -> true | false`                        check if a point (x0, y0) is inside rect (x, y, w, h)

`box.hit_edges(x0, y0, d, x, y, w, h)` \                             hit test for edges and corners
`-> hit, left, top, right, bottom`

**edge snapping**

`box.snap_edges(d, x, y, w, h, rectangles[, opaque])` \              snap the sides of a rectangle against a list
`-> x, y, w, h`                                                      of rectangles of form `{{x=,y=,w=,h=},...}`.
																							if `opaque = true`, the rectangles are considered
																							opaque, in which case they must be sorted
																							front-to-back.

`box.snap_pos(d, x, y, w, h, rectangles[, opaque])` \                snap the position of a rectangle against a list
`-> x, y, w, h`                                                      of rectangles.


`box.snapped_edges(d, x1, y1, w1, h1, x2, y2, w2, h2[, opaque])` \   check if two boxes are snapped and on which edges.
`-> snapped, left, top, right, bottom`

**overlapping test**

`box.overlapping(x1, y1, w1, h1, x2, y2, w2, h2) -> true | false`		check if two boxes overlap.

**clipping**

`box.clip(x, y, w, h, x0, y0, w0, h0) -> x1, y1, w1, h1`					intersect two normalized boxes

**bounding box**

`box.bounding_box(x1, y1, w1, h1, x2, y2, w2, h2)` \                 join two normalized boxes
`-> x, y, w, h`

-------------------------------------------------------------------- -----------------------------------------------------


## OOP API

Operations never mutate the object, instead they return a new one.

-------------------------------------------------------------------- -----------------------------------------------------
`box(x, y, w, h) -> box`                                             create a new box object
`box.x, box.y, box.w, box.h`                                         box coordinates (for reading and writing)
`box:rect() -> x, y, w, h` <br> `box() -> x, y, w, h`                coordinates unpacked
`box:corners() -> x1, y1, x2, y2`                                    left,top and right,bottom corners
`box:align(halign, valign, parent_box) -> box`                       align
`box:vsplit(i, sh) -> box`                                           split vertically
`box:hsplit(i, sw) -> box`                                           split horizontally
`box:nsplit(i, n, direction) -> box`                                 split in equal parts
`box:translate(x0, y0) -> box`                                       translate
`box:offset(d) -> box`                                               offset by d (outward if d is positive)
`box:fit(parent_box, halign, valign) -> box`                         enlarge/shrink-to-fit and align
`box:hit(x0, y0) -> true | false`                                    hit test
`box:hit_edges(x0, y0, d) -> hit, left, top, right, bottom`          hit test for edges
`box:snap_edges(d, boxes) -> box`                                    snap the edges to a list of boxes
`box:snap_pos(d, boxes) -> box`                                      snap the position
`box:overlapping(box) -> true | false`											overlapping test
`box:clip(box) -> box`																clip box to fit inside another box
`box:join(box)`                                                      make box the bounding box of itself and another box
-------------------------------------------------------------------- -----------------------------------------------------
