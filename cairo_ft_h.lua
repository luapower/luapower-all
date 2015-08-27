--result of `cpp cairo-ft.h` from cairo 1.12.3
local ffi = require'ffi'
require'cairo_h'
require'freetype_h'

ffi.cdef[[
cairo_font_face_t * cairo_ft_font_face_create_for_ft_face (FT_Face face, int load_flags);

typedef enum {
    CAIRO_FT_SYNTHESIZE_BOLD = 1 << 0,
    CAIRO_FT_SYNTHESIZE_OBLIQUE = 1 << 1
} cairo_ft_synthesize_t;

void cairo_ft_font_face_set_synthesize (cairo_font_face_t *font_face, unsigned int synth_flags);
void cairo_ft_font_face_unset_synthesize (cairo_font_face_t *font_face, unsigned int synth_flags);
unsigned int cairo_ft_font_face_get_synthesize (cairo_font_face_t *font_face);
FT_Face cairo_ft_scaled_font_lock_face (cairo_scaled_font_t *scaled_font);
void cairo_ft_scaled_font_unlock_face (cairo_scaled_font_t *scaled_font);
]]
