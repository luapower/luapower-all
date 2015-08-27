---
tagline: base class for controls
---

## `require'winapi.controlclass'`

This module implements the `Control` class which is the base class for
controls. `Control` is for subclassing, not for instantiation.
Nevertheless, it contains properties that are common to all controls
which are documented here.

## Control

### Hierarchy

* [Object][winapi.object]
	* [VObject][winapi.vobject]
		* [BaseWindow][winapi.basewindowclass]
			* Control

### Initial fields and properties

<div class=small>

__NOTE:__ in the table below `i` means initial field, `r` means property
which can be read, `w` means property which can be set.

----------------------- -------- ----------------------------------------- -------------- ---------------------
__field/property__		__irw__	__description__									__default__		__reference__
anchors.left				irw		left anchor											true
anchors.top					irw		top anchor											true
anchors.right				irw		right anchor										false
anchors.bottom				irw		bottom anchor										false
parent						irw		control's parent														Get/SetParent
----------------------- -------- ----------------------------------------- -------------- ---------------------
</div>

### Anchors

Anchors are a simple but very powerful way of doing layouting (if you grew
up with Delphi like I did then you know what I mean).
This is how they work: setting an anchor on a side of a control fixates
the distance between that side and the same side of the parent control,
so that when the parent is moved/resized, the child is also moved/resized
in order to preserve the initial distance. With anchors alone you can
define pretty much every elastic layout that you see in typical desktop apps
and you can do that without having to be explicit about the relationships
between controls or having to specify percentages.
So try'em out, you'll love'em!
