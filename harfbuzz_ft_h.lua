--hb-ft.h from harfbuzz 1.8.2
local ffi = require'ffi'
require'harfbuzz_h'
require'freetype_h'

ffi.cdef[[
hb_face_t * hb_ft_face_create (FT_Face ft_face, hb_destroy_func_t destroy);
hb_face_t * hb_ft_face_create_cached (FT_Face ft_face);
hb_face_t * hb_ft_face_create_referenced (FT_Face ft_face);

hb_font_t * hb_ft_font_create (FT_Face ft_face, hb_destroy_func_t destroy);
hb_font_t * hb_ft_font_create_referenced (FT_Face ft_face);
FT_Face     hb_ft_font_get_face (hb_font_t *font);
void        hb_ft_font_set_load_flags (hb_font_t *font, int load_flags);
int         hb_ft_font_get_load_flags (hb_font_t *font);
void        hb_ft_font_changed (hb_font_t *font);
void        hb_ft_font_set_funcs (hb_font_t *font);
]]
