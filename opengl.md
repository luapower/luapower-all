---
tagline: OpenGL C API
---

The OpenGL API is not usually found in a OS as a straight C library, or at least not all of it is.
Instead, the OS supplies a loader API (called WGL in Windows, GLX in Linux, CGL in MacOS X) through
which you retrieve pointers to actual OpenGL functions. So while the OpenGL functions and constants
themselves are standard, you can only get access to a working OpenGL namespace through a
platform-specific API.

### `local gl = require'winapi.gl11'`

Get an OpenGL 1.1 namespace via WGL.

### `local gl = require'winapi.gl21'`

Get an OpenGL 2.1 namespace via WGL.

Functions are discovered automatically through WGL and their pointers
memoized for later calls. Below are the function prototypes and
constants that are accessible in the `gl` namespace depending on
which OpenGL version you loaded:

  * [common OpenGL C types][gl_types]
  * [OpenGL 1.1 constants][gl_consts11]
  * [OpenGL 1.1 function prototypes][gl_funcs11]
  * [OpenGL 2.1 constants][gl_consts21]
  * [OpenGL 2.1 function pointer prototypes][gl_funcs21]

Pointer types like eg. `PFNGLDRAWARRAYSINDIRECTPROC` will be accessible
as `gl.glDrawArraysIndirect()`.

### `local glu = require'glu'`

The [GLU API][glu_lua] contains auxiliary utilities that let you set a perspective transform
or an orthogonal transform or move the camera, among other things. [glu_lua] implements a few of these
for environments that don't have a GLU implementation.

### `local glut = require'glut'`

The [GLUT API] lets you render the Utah Teapot (other stuff not included).

### `local wgl = require'winapi'`
### `require'winapi.wgl'`

The [WGL API][winapi.wgl] provides `wglCreateContext` for creating an OpenGL context on a HDC.
It also provides `wglGetProcAddress` for discovery of OpenGL functions.

For a straight application of the WGL API see module [winapi.wglpanel].

### `local wglex = require'winapi'`
### `require'winapi.wglext'`

The [WGLEXT API][winapi.wglext] provides various Windows-specific OpenGL extensions.

## TODO

  * make OpenGL constants C enums and access them through a proxy table into ffi.C.
  * make a binding to regal?


[gl_types]:     https://github.com/luapower/opengl/blob/master/gl_types.lua
[gl_consts11]:  https://github.com/luapower/opengl/blob/master/gl_consts11.lua
[gl_funcs11]:   https://github.com/luapower/opengl/blob/master/gl_funcs11.lua
[gl_consts21]:  https://github.com/luapower/opengl/blob/master/gl_consts21.lua
[gl_funcs21]:   https://github.com/luapower/opengl/blob/master/gl_funcs21.lua
[glut api]:     https://github.com/luapower/glut/blob/master/glut.lua
[glu_lua]:      https://github.com/luapower/opengl/blob/master/glu_lua.lua

[winapi.wgl]:       https://github.com/luapower/winapi/blob/master/winapi/wgl.lua
[winapi.wglext]:    https://github.com/luapower/winapi/blob/master/winapi/wglext.lua
[winapi.wglpanel]:  https://github.com/luapower/winapi/blob/master/winapi/wglpanel.lua

