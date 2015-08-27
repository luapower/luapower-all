---
tagline: OpenGL scene graph rendering
---

## `local SG = require'sg_gl'`

## OpenGL scene graph objects

~~~{.lua}
<object> = {
	<group> | ...
}

<group> =
	type = 'group', <object>, ...

~~~

### `SG:new([cache]) -> sg`

Create a new scene graph render to render OpenGL scene graph objects
on the currently active OpenGL context.

### `sg:free()`

Free the render and any associated resources.

## Extensions

  * [sg_gl_mesh]
  * [sg_gl_shape]
  * [sg_gl_obj]
