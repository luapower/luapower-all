--cairo freetype extension
local M = require'cairo'
local ffi = require'ffi'
local C = M.C
require'cairo_ft_h'
local ft = require'freetype'

function M.cairo_ft_font_face_create_for_ft_face(ft_face, load_flags)
	local key = ffi.new'cairo_user_data_key_t[1]';
	local font_face = ffi.gc(C.cairo_ft_font_face_create_for_ft_face(ft_face, load_flags or 0), M.cairo_font_face_destroy)
	local status = C.cairo_font_face_set_user_data(font_face, key, ft_face, ffi.cast('cairo_destroy_func_t', ft.FT_Done_Face))
	if status ~= 0 then
		C.cairo_font_face_destroy(font_face)
		ft.FT_Done_Face(ft_face)
	end
	return font_face
end
