---
tagline: wavefront OBJ parser
---

## `local obj_parser = require'obj_parser'`

### `obj_parser.parse(file, handlers)`

Parses an obj file calling a specific handler for each piece of the file.

Here's a template for the handlers table:

~~~{.lua}
handlers = {
  vertex = function(x,y,z) end,
  normal = function(x,y,z) end,
  texcoord = function(u,v,w) end,
  start_face = function() end,
  face_vtn = function(v,t,n) end,
  end_face = function() end,
  line = function(v,t) end,
  material_def = function(material_name) end,
  material_attr = function(cmd, ...)
    if cmd ##  'ka' or cmd  'kd' or cmd == 'ks' then
      local r,g,b = ...
    elseif cmd ##  'illum' or cmd   'ns' or cmd ##  'd' or cmd  'tr' then
      local N = ...
    elseif ({'map_ka', 'map_kd', 'map_ks', 'map_ns', 'map_d', 'map_bump', 'bump', 'disp', 'decal'})[cmd] then
      local filepath = ...
    end
  end,
  material = function(material_name) end,
  group = function(group_names_t) end,
  smoothing_group = function(group_names_t) end,
}
~~~

----
See also: [obj_loader]
