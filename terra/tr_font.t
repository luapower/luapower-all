--[[

	Font loading and unloading and setting the font size.

	Fonts are kept in two LRU caches: one that is bytesize-limited for memory
	fonts and one that is count-limited for memory-mapped fonts.

]]

if not ... then require'terra/tr_test'; return end

setfenv(1, require'terra/tr_types')

terra Font:init(r: &Renderer, id: int)
	fill(self)
	self.r = r
	self.id = id
	self.selected_face_index = -1
	r.load_font(id, &self.file_data, &self.file_size, &self.mmapped)
	assert(self.file_data == nil or self.file_size > 0)
end

terra Font:free()
	assert(self.file_data ~= nil)
	assert(self.file_size > 0)
	self.faces:free()
	self.r.unload_font(self.id, self.file_data, self.file_size, self.mmapped)
	self.file_data = nil
	self.file_size = 0
	dealloc(self)
end

terra Font:get_selected_face()
	return self.faces:at(self.selected_face_index)
end

terra Font:select_face(face_index: int)
	assert(self.file_data ~= nil)
	if face_index == self.selected_face_index then
		return self.selected_face
	end

	var face = self.faces:getat(face_index, [FontFace.empty])

	if face.ft_face == nil then
		self.selected_face_index = -1

		face.ft_load_flags =
				FT_LOAD_COLOR
			or FT_LOAD_PEDANTIC
			--or FT_LOAD_NO_HINTING
			--or FT_LOAD_NO_AUTOHINT
			--or FT_LOAD_FORCE_AUTOHINT

		face.ft_render_flags = FT_RENDER_MODE_LIGHT

		if FT_New_Memory_Face(self.r.ft_lib,
			[&uint8](self.file_data), self.file_size,
			face_index, &face.ft_face) ~= 0
		then
			face:free()
			return nil
		end

		face.hb_font = hb_ft_font_create_referenced(face.ft_face)
		if face.hb_font == nil then
			face:free()
			return nil
		end

		hb_ft_font_set_load_flags(face.hb_font, face.ft_load_flags)
	end

	self.selected_face_index = face_index
	return face
end

terra FontFace:free()
	if self.hb_font ~= nil then
		hb_font_destroy(self.hb_font)
		self.hb_font = nil
	end
	if self.ft_face ~= nil then
		FT_Done_Face(self.ft_face)
		self.ft_face = nil
	end
end

terra FontFace:set_size(size: num)
	if self.size == size then
		return
	end

	--find the size index closest to input size.
	var size_index: int
	var fixed_size = size
	var found = false
	var best_diff: int16 = 0x7fff
	for i = 0, self.ft_face.num_fixed_sizes do
		var sz = self.ft_face.available_sizes[i]
		var this_size = sz.height
		var diff = abs(size - this_size)
		if diff < best_diff then
			size_index = i
			fixed_size = this_size
			found = true
		end
	end

	if found then
		self.scale = size / fixed_size
		assert(FT_Select_Size(self.ft_face, size_index) == 0)
	else
		self.scale = 1
		assert(FT_Set_Pixel_Sizes(self.ft_face, fixed_size, 0) == 0)
	end

	hb_ft_font_changed(self.hb_font)

	self.size = size
end

terra FontFace:get_ascent              () return [num](self.ft_face.size.metrics.ascender ) * self.scale / 64 end
terra FontFace:get_descent             () return [num](self.ft_face.size.metrics.descender) * self.scale / 64 end
terra FontFace:get_height              () return [num](self.ft_face.size.metrics.height   ) * self.scale / 64 end
terra FontFace:get_scale_y             () return [num](self.ft_face.size.metrics.y_scale  ) * self.scale / 65536 end
terra FontFace:get_underline_position  () return [num](self.ft_face.underline_position    ) * self.scale_y / 64 end
terra FontFace:get_underline_thickness () return [num](self.ft_face.underline_thickness   ) * self.scale_y / 64 end

terra Span:get_face()
	var face = self.font:select_face(self.font_face_index)
	if face ~= nil then
		face:set_size(self.font_size)
	end
	return face
end

--font cache -----------------------------------------------------------------

terra Renderer:font(font_id: int): &Font
	if font_id == -1 then
		return nil --reserve -1 as default "font not set" value.
	end
	var font_i, pair = self.mem_fonts:get(font_id)
	if font_i == -1 then
		font_i, pair = self.mmapped_fonts:get(font_id)
	end
	if font_i == -1 then
		var font: Font
		font:init(self, font_id)
		if font.file_data ~= nil then
			var cache = iif(font.mmapped, &self.mmapped_fonts, &self.mem_fonts)
			var mfont = alloc(Font)
			@mfont = font
			var font_i, pair = cache:put(font_id, mfont)
			return mfont
		else
			return nil
		end
	else
		return pair.val
	end
end

terra forget_font(self: &Renderer, font_id: int)
	if font_id == -1 then
		return
	end
	var font_i, pair = self.mem_fonts:get(font_id)
	--NOTE: we forget the font twice because get() increases refcount.
	if font_i ~= -1 then
		self.mem_fonts:forget(font_i)
		self.mem_fonts:forget(font_i)
		return
	end
	font_i, pair = self.mmapped_fonts:get(font_id)
	if font_i ~= -1 then
		self.mmapped_fonts:forget(font_i)
		self.mmapped_fonts:forget(font_i)
		return
	end
end

--font API -------------------------------------------------------------------

terra Renderer:font_face_num(font: &Font): int
	if font == nil then return -1 end
	var ft_face: FT_Face = nil
	var ok = FT_New_Memory_Face(self.ft_lib,
		[&uint8](font.file_data), font.file_size,
		-1, &ft_face) == 0
	var face_num = iif(ok, ft_face.num_faces, 0)
	FT_Done_Face(ft_face)
	return face_num
end

