local hb = require'harfbuzz'

print('version: ', hb.hb_version())
print('vstring: ', hb.hb_version_string())

local stdio = require'stdio'
local buf, sz = stdio.readfile('media/fonts/DejaVuSerif.ttf')

local blob = hb.hb_blob_create(buf, sz, hb.HB_MEMORY_MODE_WRITABLE, nil, nil)

local face = hb.hb_face_create(blob, 0)
print('upem:   ', face:get_upem())
print('gcount: ', face:get_glyph_count())

local font = hb.hb_font_create(face)
print('scale:  ', font:get_scale())
print('ppem:   ', font:get_ppem())

local buf = hb.hb_buffer_create()
buf:add_utf8('hello')
local info = buf:get_glyph_infos()
for i=0,buf:get_length()-1 do
	local cp = info[i].codepoint
	print(cp, font:get_glyph_h_advance(cp)) --TODO: implement font callbacks for these
end
