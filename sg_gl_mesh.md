---
tagline: OpenGL scene graph meshes
---

## `require'sg_gl_mesh'`

Extends [sg_gl] to render mesh type objects.

## Mesh objects

A mesh is a type of OpenGL scene graph object that describes a complete 3D object to be stored in VRAM
by means of OpenGL's VBO (vertex buffer objects) and IBO (index buffer objects) and then rendered
via OpenGL's `glDrawElements`.

A mesh is conceptually an array of vertex records, each record containing the position in 3D space of the vertex,
a texture reference and texture mapping coordinates (if the object is textured), a normal vector for lighting
computation (if lighting is used), and a RGBA color (if the object is colored instead of or in addition to being textured).

Because many times 3D objects have the same vertex positions and only differ in texture or some other aspect,
or they are missing some attributes altogether (eg. a textured object would usually not have color information),
OpenGL provides ways to specify vertex information more efficiently to save VRAM.

In particular, you can have vertex, normal, texcoord and color information in separate arrays (called VBOs), or you can
have it all packed in a single array (called interleaved VBO), or you can have vertex and normals packed together in one
interleaved array and texcoords in a separate array, or any combination thereof.

Also, you can choose to render all the vertices in the VBO (this is the default), or you can pick only specific
vertices from the VBO to be rendered by way of an array of VBO indices (called IBO).
This allows you to pack multiple 3D objects into one big shared VBO and render them individually using IBOs,
but more usually, it allows you to bind different textures to different parts of the VBO.

~~~{.lua}
<mesh_object> = {
	type = 'mesh',
	vbo_v = <vbo>, --required, vertices
	vbo_n = <vbo>, --optional, normals
	vbo_t = <vbo>, --optional, texcoords
	vbo_c = <vbo>, --optional, colors
	ibo = <ibo>,
	ibo_partitions = {<partition1>,...}, --optional
	texture = <texture>, --optional
	mode = <mode>,       --optional only if there are partitions and they all specify a mode
}

<vbo> = {
	layout = S, --any combination of letters 'v', 'n', 't', and 'c' in any order
	data = CDATA, size = N | values = {N,...},
	usage = 'static' | 'dynamic' | 'stream' (static),
}

<ibo> = {
	<ibo_cdata_size> | <ibo_cdata_count> | <ibo_values> | <ibo_create>

	usage = 'static' | 'dynamic' | 'stream' (static),
}

<ibo_cdata_size> =
	cdata = CDATA, size = N
<ibo_cdata_count> =
	cdata = CDATA, count = N
<ibo_values> =
	{N,...}
<ibo_create> =
	from = N, count = N

<partition> = {
	texture = <texture>, --optional, defaults to mesh_object.texture
	mode = <mode>,       --optional if mesh_object specifies a mode
	from = N, --
	count = N,
	transparent = true | false (false)
}

<texture> = {
	<image_texture> | <surface_texture>
}

<image_texture> =
	type = 'image',
	file = <imagefile source>, --see imagefile

<surface_texture> =
	type = 'surface',
	w = N, --width
	h = N, --height
	object = <cairo scene graph object>


<mode> = 'points' | 'line_strip' | 'line_loop' | 'lines' | 'triangles' |
         'triangle_strip' | 'triangle_fan' | 'quads' | 'quad_strip' | 'polygon'

~~~

## VBOs

A VBO is an array of records. The record's structure is given by the `layout` property, a string consisting
of any combination of the letters `v`, `n`, `t` and `c` specifying which attributes make up the record and in which order.

**letter** **meaning**   **specifically**  **number type**
---------- ------------- ----------------- ---------------
v          vertices      x,y,z             32bit float
n          normals       nx,ny,nz          32bit float
t          texcoords     u,v               32bit float
c          colors        r,g,b,a           32bit float

So a VBO with a 'vtn' layout is an interleaved VBO of the form {v1.x,v1.y,v1.z,v1.u,v1.v,v1.nx,v1.ny,v1.nz,v2.x,v2.y,...}.
A VBO with a 't' layout has the form {v1.u,v1.v,v2.u,v2.v,...} and so on.
If values are given as `cdata`, it must be an array of 32bit floats and either `count` or `size` must also be set.
Given as `values` it must be table of Lua numbers which will be converted to 32bit floats upon uploading.

## IBOs

An IBO is an array of indices. Given as `cdata` it must be an array of uint32_t if larger than 64k entries,
uint16_t if larger than 255 entries, and uint8_t if smaller than 256 entries. Given as `values`,
it must be an array of Lua numbers. If `from` and `count` is given instead, an IBO with consecutive indices is created.

An IBO can also be partitioned so that different contiguous segments of it can be rendered with a different mode and/or texture.

## Textures

Textures can be either [image files][imagefile] or [cairo scene graphs][sg_cairo].

