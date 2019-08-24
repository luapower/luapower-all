
--Painting rasterized glyph runs into a cairo surface.

if not ... then require'terra/tr_test'; return end

setfenv(1, require'terra/tr_types')
require'terra/tr_rasterize'

--NOTE: clip_left and clip_right are relative to glyph run's origin.
terra Renderer:paint_glyph_run(
	cr: &context, gr: &GlyphRun, i: int, j: int,
	ax: num, ay: num, clip: bool, clip_left: num, clip_right: num
): {}

	if not clip and j > 2 and gr.font_size < 50 then
		var sr, sx, sy = self:rasterize_glyph_run(gr, ax, ay)
		self:paint_surface(cr, sr, sx, sy, false, 0, 0)
		inc(self.paint_glyph_num, j)
		return
	end

	var surfaces = self:glyph_surfaces(gr, i, j, ax, ay)
	for sr, sx, sy in surfaces do
		if clip then
			--make clip_left and clip_right relative to bitmap's left edge.
			clip_left  = clip_left + ax - sx
			clip_right = clip_right + ax - sy
		end
		self:paint_surface(cr, sr, sx, sy, clip, clip_left, clip_right)
		inc(self.paint_glyph_num, j-i)
	end

end

terra Layout:paint_text(cr: &context)

	assert(self.state >= STATE_ALIGNED)
	assert(self.clip_valid)

	var segs = &self.segs
	var lines = &self.lines

	for line_i = self.first_visible_line, self.last_visible_line + 1 do
		var line = lines:at(line_i)

		var ax = self.x + line.x
		var ay = self.y + self.baseline + line.y

		var seg = line.first_vis --can be nil
		while seg ~= nil do
			if seg.visible then

				var gr = self:glyph_run(seg)
				var x, y = ax + seg.x, ay

				--[[
				--TODO: subsegments
				if #seg > 0 then --has sub-segments, paint them separately
					for i = 1, #seg, 5 do
						var i, j, text_run, clip_left, clip_right = unpack(seg, i, i + 4)
						rs:setcontext(cr, text_run)
						paint_glyph_run(cr, rs, run, i, j, x, y, true, clip_left, clip_right)
					end
				else
				]]

				self.r:setcontext(cr, seg.span)
				self.r:paint_glyph_run(cr, gr, 0, gr.glyphs.len, x, y, false, 0, 0)
				--end

			end
			seg = seg.next_vis
		end
	end
end

terra Layout:paint_rect(cr: &context,
	x: num, y: num, w: num, h: num,
	color: color, opacity: num
)
	cr:rgba(color:apply_alpha(opacity))
	cr:new_path()
	cr:rectangle(x, y, w, h)
	cr:fill()
end

