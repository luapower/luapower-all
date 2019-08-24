
--Font loading and unloading and setting the font size.

if not ... then require'terra/tr_test'; return end

setfenv(1, require'terra/tr_types')

terra Font:init(r: &Renderer)
	fill(self)
	self.r = r
	self.ft_load_flags =
		   FT_LOAD_COLOR
		or FT_LOAD_PEDANTIC
		--or FT_LOAD_NO_HINTING
		--or FT_LOAD_NO_AUTOHINT
		--or FT_LOAD_FORCE_AUTOHINT
	self.ft_render_flags = FT_RENDER_MODE_LIGHT
end

terra Font:get_id()
	return self.r.fonts:index(self)
end

terra Font:ref()
	if self.refcount == 0 then

		self.r.load_font(self.id, &self.file_data, &self.file_size)

		if self.file_data == nil then
			self:free()
			return false
		end

		if FT_New_Memory_Face(self.r.ft_lib,
			[&uint8](self.file_data),
			self.file_size, 0, &self.ft_face) ~= 0
		then
			self:free()
			return false
		end

		self.hb_font = hb_ft_font_create_referenced(self.ft_face)
		if self.hb_font == nil then
			self:free()
			return false
		end

		hb_ft_font_set_load_flags(self.hb_font, self.ft_load_flags)
	end

	inc(self.refcount)
	return true
end

terra Font:free()
	assert(self.refcount == 0)
	if self.hb_font ~= nil then
		hb_font_destroy(self.hb_font)
		self.hb_font = nil
	end
	if self.ft_face ~= nil then
		FT_Done_Face(self.ft_face)
		self.ft_face = nil
	end
	if self.file_data ~= nil then
		self.r.unload_font(self.id, &self.file_data, &self.file_size)
		self.file_data = nil
	end
end

terra Font:unref()
	assert(self.refcount > 0)
	dec(self.refcount)
	if self.refcount == 0 then
		self:free()
	end
end

terra Font:setsize(size: num)

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

	self.size = size
	var m = self.ft_face.size.metrics
	self.ascent  = [num](m.ascender ) * self.scale / 64.f
	self.descent = [num](m.descender) * self.scale / 64.f

	hb_ft_font_changed(self.hb_font)
end
