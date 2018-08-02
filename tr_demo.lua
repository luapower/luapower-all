
local tr = require'tr'
local nw = require'nw'
local bundle = require'bundle'
local gfonts = require'gfonts'
local time = require'time'
local box2d = require'box2d'

local tr = tr()

nw:app():maxfps(1/0)

local win = nw:app():window{
	x = 100, y = 60,
	w = 1800, h = 900,
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

local function rect(cr, x, y, w, h)
	cr:save()
	cr:rectangle(x, y, w, h)
	cr:line_width(1)
	cr:rgb(1, 1, 0)
	cr:stroke()
	cr:restore()
end

local text = require'glue'.readfile('winapi_history.md')

function win:repaint()
	local cr = self:bitmap():cairo()
	--cr:rgb(1, 1, 1); cr:paint(); cr:rgb(0, 0, 0)
	cr:rgb(0, 0, 0); cr:paint(); cr:rgb(1, 1, 1)

	if false then

		local segs = tr:shape{
			('\xF0\x9F\x98\x81'):rep(2), font_name = 'NotoColorEmoji,34',
		}
		local x, y, w, h = 100, 100, 80, 80
		rect(cr, x, y, w, h)
		tr:paint(cr, segs, x, y, w, h, 'center', 'bottom')

	elseif true then

		local t0 = time.clock()
		--local s1 = ('gmmI '):rep(1)
		--local s2 = ('fi AV (ثلاثة 1234 خمسة) '):rep(1)
		--local s3 = ('Hebrew (אדםה (adamah))'):rep(1)

		local x, y, w, h = box2d.offset(-50, 0, 0, win:client_size())
		rect(cr, x, y, w, h)

		self.segs = tr:shape{
			font_name = 'open sans,14',
			--font_name = 'amiri,20',
			--dir = 'rtl',
			--{'A'},
			{text
				, {''..('\xF0\x9F\x98\x81'):rep(3)..'', font_name = 'NotoColorEmoji,34'}
			}
			--{('ABCD efghi jkl 12345678 '):rep(500)},
			--{('خمسة ABC '):rep(100), {'abc def \r\r\n\nghi jkl ', font_size = 30}, 'DEFG'},
			--{('ABCD EFGH abcd efgh 1234'):rep(200)},
		}
		self.lines = self.segs:layout(x, y, w, h, 'center', 'bottom')
		self.lines:paint(cr)

		if self.rr then
			rect(cr, unpack(self.rr))
		end

		local s = (time.clock() - t0)
		print(string.format('%0.2f ms    %d fps', s * 1000, 1 / s))
	end

	print(string.format('word  cache size:  %d KB', tr.glyph_runs.total_size / 1024))
	print(string.format('word  count:       %d   ', tr.glyph_runs.lru.length))
	print(string.format('glyph cache size:  %d KB', tr.rs.glyphs.total_size / 1024))
	print(string.format('glyph count:       %d   ', tr.rs.glyphs.lru.length))
end

function win:mousemove(mx, my)
	if not self.lines then return end

	local x, y, w, h = box2d.offset(-50, 0, 0, win:client_size())

	local seg, x, y, w, h = self.lines:hit_test(x, y, mx, my)
	if seg then
		self.rr = {x, y, w, h}
	else
		self.rr = false
	end
	self:invalidate()
end

nw:app():run()

tr:free()
