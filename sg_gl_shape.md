---
tagline:  OpenGL scene graph shapes
---

## `require'sg_gl_shape'`

Extends [sg_gl] to render shape objects.

## Shape objects

A shape is a type of OpenGL scene graph object that describes a 3D object in a state-machine kind of language.
Internally, the shape description is converted into a [mesh object][sg_gl_mesh] which is then rendered.

~~~{.lua}
<shape_object> = {
	type = 'shape',
	<mode> |
	'color', r, g, b, a |
}

<mode> = see sg_gl_mesh for available modes.
~~~
