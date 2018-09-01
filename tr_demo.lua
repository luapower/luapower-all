
local tr = require'tr'
local nw = require'nw'
local bundle = require'bundle'
local gfonts = require'gfonts'
local time = require'time'
local box2d = require'box2d'
local color = require'color'

local tr = tr()

local win = nw:app():window{
	x = 100, y = 60,
	w = 550, h = 900,
	--w = 800, h = 600,
}

local function font(file, name)
	local name = name or assert(file:match('([^\\/]+)%.[a-z]+$')):lower()
	local font = tr:add_font_file(file, name)
	--print(font:internal_name())
end

local function gfont(name)
	local file = assert(gfonts.font_file(tr.rs.font_db:parse_font(name)))
	font(file, name)
end

gfont'eb garamond'
gfont'eb garamond italic'
gfont'eb garamond bold'
gfont'eb garamond bold italic'
gfont'dancing script'
gfont'open sans'
gfont'open sans italic'
gfont'open sans bold italic'
gfont'open sans 300'
gfont'open sans 300 italic'
font'media/fonts/NotoColorEmoji.ttf'
--font'media/fonts/NotoEmoji-Regular.ttf'
--font'media/fonts/EmojiSymbols-Regular.ttf'
--font'media/fonts/SubwayTicker.ttf'
--font'media/fonts/dotty.ttf'
--font'media/fonts/ss-emoji-microsoft.ttf'
--font'media/fonts/Hand Faces St.ttf'
--font'media/fonts/FSEX300.ttf'
font'media/fonts/amiri-regular.ttf'

--tr.rs.font_db:dump()

local function rect(cr, col, x, y, w, h)
	local r, g, b, a = color.parse(col, 'rgb')
	cr:save()
	cr:new_path()
	cr:rectangle(x, y, w, h)
	cr:line_width(1)
	cr:rgba(r, g, b, a or 1)
	cr:stroke()
	cr:restore()
end

local function triangle(cr, col, x, y, w, angle)
	local r, g, b, a = color.parse(col, 'rgb')
	angle = math.rad(angle)
	local h = math.sqrt(3) / 2 * w
	cr:save()
	cr:new_path()
	cr:translate(x, y)
	cr:rotate(angle)
	cr:translate(-w/2, -h)
	cr:move_to(0, 0)
	cr:rel_line_to(w, 0)
	cr:rel_line_to(-w/2, h)
	cr:close_path()
	cr:rgba(r, g, b, a or 1)
	cr:fill()
	cr:restore()
end

local function straightline(cr, col, x, y, x2, y2)
	local r, g, b, a = color.parse(col, 'rgb')
	cr:save()
	cr:new_path()
	cr:move_to(x, y)
	cr:line_to(x2, y2)
	cr:line_width(1)
	cr:rgba(r, g, b, a or 1)
	cr:stroke()
	cr:restore()
end

local function vector(cr, col, x, y, x2, y2)
	straightline(cr, col, x, y, x2, y2)
	triangle(cr, col, x2, y2, 8, -90 + math.deg(math.atan2(y2-y, x2-x)))
end

local function dot(cr, col, x, y, size)
	local r, g, b, a = color.parse(col, 'rgb')
	cr:save()
	cr:new_path()
	cr:circle(x, y, size or 5)
	cr:rgba(r, g, b, a or 1)
	cr:fill()
	cr:restore()
end

local text = require'glue'.readfile('winapi_history.md')

local segs, lines, cursor

function win:repaint()
	local cr = self:bitmap():cairo()
	--cr:rgb(1, 1, 1); cr:paint(); cr:rgb(0, 0, 0)
	cr:rgb(0, 0, 0); cr:paint(); cr:rgb(1, 1, 1)
	--cr:identity_matrix():rotate_around(500, 400, math.rad(-30))

	local t0 = time.clock()

	if false then

		local segs = tr:shape{
			('\xF0\x9F\x98\x81'):rep(2), font_name = 'NotoColorEmoji,34',
		}
		local x, y, w, h = 100, 100, 80, 80
		rect(cr, '#888', x, y, w, h)
		tr:paint(cr, segs, x, y, w, h, 'center', 'bottom')

	elseif true then

		--local s1 = ('gmmI '):rep(1)
		--local s2 = ('fi AV (ثلاثة 1234 خمسة) '):rep(1)
		--local s3 = ('Hebrew (אדםה (adamah))'):rep(1)

		local x, y, w, h = box2d.offset(-50, 0, 0, win:client_size())
		rect(cr, '#888', x, y, w, h)

		local t = {
			line_spacing = 1.2,
			paragraph_spacing = 1.5,
			--{'A'},
			font_name = 'amiri,100',
			--font_name = 'eb garamond, 50',

			--'abc', 'def', 'ghi',

			--'mff\n12',

			--{font_size = 30, 'We find \u{202B}פעילות הבינאום\u{202C}\u{200E} 5 times.\n'},

			--'פעילות ABC הבינאום',
			--'ABC DEF \nGHI\n',

			--'مفاتيح ABC DEF\n',
			--dir = 'rtl',
			--'ABC DEF السَّلَامُ عَلَيْكُمْ مفاتيح ',
			--'السَّلَامُ عَلَيْكُمْ',
			'ffi السَّلَامُ',

			--dir = 'rtl', 'مفاتيح ABC', '\u{2029}', {dir = 'ltr', 'مفاتيح ABC'},
			--'XXX פעילות ABC הבינאום DEF',

			--'مفاتيح 123 456 مفاتيح abc',
			--{'المفاتي','ح\n'},
			--{color = '#ff0', 'ال  ( مف ) اتيح', font_size = 81},
			--'\r\n',
			--{color = '#f6f', '  A(B)C  .  المفاتيح  '},

			--'\u{2029}', --paragraph split

			--{
			--line_spacing = 1,

				--'abc    def       ghi   123   xxx',

				features = 'smcp liga=1 +kern',

				--{'f'},{color = '#ff0','f'},{'i'},
				--'Td', 'fb\n',
				--{'Td'}, {color = '#ff0', 'f'}, {color = '#0ff', 'f'}, {color = '#f0f', 'i'}, {'b\n'}, 'abc def ghi',
				--' abc',
				--'abc', {'def\n'}, 'ABC 123',
				--t=0,
				--{t=1, nowrap = true, 'abc def'}, ' xyz ',
				--{t=2, nowrap = true, '12 abc 789'}, ' zyz', {x = 20, y = -30, font_size = 40, '2'},
				--{t=3, nowrap = true, 'ABC def GH'},

				--font_name = 'open sans, 200',

				--multiple glyphs with the same cluster value
				--{'\x15\x09\0\0\x4D\x09\0\0\x15\x09\0\0\x3F\x09\0\0\x15\x09\0\0', charset = 'utf32'},
				--{'\x15\x09\0\0\x4D\x09\0\0\x15\x09\0\0\x3F\x09\0\0\x15\x09\0\0', charset = 'utf32'},

				--'\u{65}\u{301}ff',
				--'i fi mTm\n\n', {i=1, 'VA', {b=1, 'Dg', {i=false, 'dT\n'}}},
			--},

			--{font_name = 'eb garamond, 100', 'ffix xfl ffi fl\n'},
			--{font_name = 'amiri, 100', 'ffix xfl ffi fl'},

			--{font_name = 'NotoColorEmoji,34', ('\xF0\x9F\x98\x81'):rep(3)},
		}

		--[[
		local utf8 = require'utf8'
		local ffi = require'ffi'
		local s,len = utf8.decode'السَّلَامُ'
		local t = {font_name = 'amiri,100'}
		for i=1,10 do
			local cp = ffi.string(s+i-1, 4)
			t[i] = {charset = 'utf32', text_len = 1, cp}
		end
		]]

		segs = segs or tr:shape(t)
		segs:layout(x, y, w, h, 'center', 'middle')
		segs:paint(cr)

		local lines = segs.lines
		local x = lines.x
		local y = lines.y + lines.baseline
		for i,line in ipairs(lines) do
			local hit = self.hit_line_i == i
			local x = x + line.x
			local y = y + line.y
			rect(cr, hit and '#f22' or '#222', x, y, line.advance_x, -line.spacing_ascent)
			rect(cr, hit and '#f22' or '#022', x, y, line.advance_x, -line.spacing_descent)
			rect(cr, hit and '#fff' or '#888', x, y, line.advance_x, -line.ascent)
			rect(cr, hit and '#0ff' or '#088', x, y, line.advance_x, -line.descent)
			dot(cr, '#fff', x, y, 6)
			dot(cr, '#ff0', x + line.advance_x, y, 6)
			local ax = x
			local ay = y
			for i,seg in ipairs(line) do
				local run = seg.glyph_run
				local hit = hit and self.hit_seg == seg
				--rect(cr, hit and '#f00' or '#555', ax + run.hlsb, ay + run.htsb, run.w, run.h)
				dot(cr, '#f0f', ax, ay, 4)
				dot(cr, '#0f0', ax + seg.advance_x, ay, 5)
				--dot(cr, '#fff', ax + run.hlsb, ay + run.htsb, 4)
				do
					local ay = ay + (seg.index - 1) * 10
					if run.rtl then
						vector(cr, '#f00', ax + seg.advance_x, ay, ax, ay + 10)
					else
						vector(cr, '#66f', ax, ay, ax + seg.advance_x, ay + 10)
					end
				end
				for i = 0, run.text_len do
					local cx = seg.offset_x + run.cursor_xs[i]
					local px = ax + cx
					local hit = hit and self.hit_cursor_i == i
					dot(cr, '#0ff', px, ay, 2)
				end
				for i = 0, run.len do
					local glyph_index = run.info[i].codepoint
					local px = i > 0 and run.pos[i-1].x_advance / 64 or 0
					local ox = run.pos[i].x_offset / 64
					local oy = run.pos[i].y_offset / 64
					dot(cr, '#ff0', ax + seg.offset_x + px + ox, ay - oy, 3)
				end
				ax = ax + seg.advance_x
			end
		end

		if self.hit_cursor_i then
			local x, y, h = lines:cursor_pos(self.hit_seg, self.hit_cursor_i)
			rect(cr, '#f00', x-4, y, 8, h)
		end

		cursor = cursor or segs:cursor()
		local x, y, h, rtl = cursor:pos()
		vector(cr, '#fff', x, y, x, y+h)
		local w = (rtl and 10 or -10)
		triangle(cr, '#fff', x-w*.8, y, w, 90)
	end

end

function win:mousemove(mx, my)
	if lines then
		self.hit_line_i, self.hit_seg, self.hit_cursor_i = lines:hit_test(mx, my)
		if cursor then
			cursor:move_to(mx, my)
		end
		self:invalidate()
	end
end

function win:keypress(key)
	if not cursor then return end

	if key == 'k' then
		require'inspect'({tr, lines}, {
			process = function(v)
				if v == '_next' or v == '_prev' then return end
				return v
			end,
		})
	elseif key == 'enter' then

		for seg_i,seg in ipairs(segs) do
			local run = seg.glyph_run
			for i=1,#run.cursor_offsets do
				print(seg_i, seg.offset + run.cursor_offsets[i], run.cursor_xs[i])
			end
		end

	end

	if key == 'right' or key == 'left' then
		cursor:move('horiz', key == 'right' and 1 or -1)
		self:invalidate()
		local t = {}
		for i = 0, cursor.seg.glyph_run.len do
			t[#t+1] = cursor.seg.glyph_run.cursor_xs[i]
		end
		print(cursor.offset, cursor.seg.index, cursor.cursor_i,
			cursor.seg.glyph_run.cursor_xs[cursor.cursor_i], pp.format(t))
	elseif key == 'up' then
		cursor:move('vert', -1)
		self:invalidate()
	elseif key == 'down' then
		cursor:move('vert', 1)
		self:invalidate()
	end
end


nw:app():run()

tr:free()
