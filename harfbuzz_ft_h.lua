--hb-ft.h from harfbuzz HEAD from May 24, 2013
local ffi = require'ffi'
require'harfbuzz_h'
require'freetype_h'

ffi.cdef[[
hb_face_t * hb_ft_face_create (FT_Face ft_face, hb_destroy_func_t destroy);
hb_face_t * hb_ft_face_create_cached (FT_Face ft_face);
hb_font_t * hb_ft_font_create (FT_Face ft_face, hb_destroy_func_t destroy);
void        hb_ft_font_set_funcs (hb_font_t *font);
FT_Face     hb_ft_font_get_face (hb_font_t *font);
]]

