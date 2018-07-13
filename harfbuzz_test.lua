
local hb = require'harfbuzz'
local ffi = require'ffi'
local glue = require'glue'
local pp = require'pp'

print('version: ', hb.version())
print('vstring: ', hb.version_string())

local s = assert(glue.readfile('media/fonts/DejaVuSerif.ttf'))
local buf, sz = ffi.cast('const char*', s), #s

local blob = hb.blob(buf, sz, hb.C.HB_MEMORY_MODE_WRITABLE, nil, nil)

local face = blob:face(0)
print('upem:   ', face:get_upem())
print('gcount: ', face:get_glyph_count())

local font = face:font()
print('scale:  ', font:get_scale())
print('ppem:   ', font:get_ppem())

local buf = hb.buffer()
buf:add_utf8('hello')
local info = buf:get_glyph_infos()
for i=0,buf:get_length()-1 do
	local cp = info[i].codepoint
	print(cp, font:get_glyph_h_advance(cp)) --TODO: implement font callbacks for these
end

pp(hb.list_shapers())
