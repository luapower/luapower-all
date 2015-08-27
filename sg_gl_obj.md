---
tagline: OpenGL scene graph OBJ meshes
---

## `require'sg_gl_obj'`

Extends [sg_gl] to render wavefront OBJ files. Uses [obj_loader]
to parse obj files into [sg_gl_mesh mesh objects][sg_gl_mesh].

## Wavefront obj objects

~~~{.lua}
<obj_object> = {
  type = 'obj',
  file = {
    path = S,
    use_cache = true | false (false),
  },
}
~~~
