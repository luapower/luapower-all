
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

local ii=0
function win:repaint()
	local cr = self:bitmap():cairo()
	--cr:rgb(1, 1, 1); cr:paint(); cr:rgb(0, 0, 0)
	cr:rgb(0, 0, 0); cr:paint(); cr:rgb(1, 1, 1)

	tr.rs.cr = cr

	if false then

		local gi = string.byte('E', 1)
		local maxi = 30--64
		local maxj = 30--64
		for j=0,maxj+5 do
			cr:line_width(1)
			cr:move_to(10+j*20+ii+.5, 0)
			cr:rel_line_to(0, 1000)
			cr:stroke()
			local x0 = j/(maxj+1)
			for i=0,maxi+5 do
				local x = (i/(maxi+1)+x0)
				local y = x > x0+1 and 4 or 0
				tr:paint_glyph(gi, ii+10+x+j*20, 20+y+i*11)
			end
		end

	elseif false then

		local runs = tr:shape{
			('\xF0\x9F\x98\x81'):rep(2), font_name = 'NotoColorEmoji,34',
		}
		local x, y, w, h = 100, 100, 80, 80
		rect(cr, x, y, w, h)
		tr:paint(runs, x, y, w, h, 'center', 'bottom')

	elseif true then

		local t0 = time.clock()
		local n = 1
		local s = require'glue'.readfile('winapi_history.md')
		for i=1,n do
			--local s1 = ('gmmI '):rep(1)
			--local s2 = ('fi AV (ثلاثة 1234 خمسة) '):rep(1)
			--local s3 = ('Hebrew (אדםה (adamah))'):rep(1)
			self.runs = self.runs or tr:shape{
				font_name = 'open sans,14',
				--font_name = 'amiri,20',
				line_spacing = 1,
				--dir = 'rtl',
				--{'A'},
				{s
					, {''..('\xF0\x9F\x98\x81'):rep(3)..'', font_name = 'NotoColorEmoji,34'}
				}
				--{('ABCD efghi jkl 12345678 '):rep(500)},
				--{('خمسة ABC '):rep(100), {'abc def \r\r\n\nghi jkl ', font_size = 30}, 'DEFG'},
				--{('ABCD EFGH abcd efgh 1234'):rep(200)},
			}

			local x, y, w, h = box2d.offset(-50, 0, 0, win:client_size())
			rect(cr, x, y, w, h)
			tr:paint(self.runs, x, y, w, h, 'center', 'bottom')
			self.runs:free()
			self.runs = false
		end

		local s = (time.clock() - t0) / n
		print(string.format('%0.2f ms    %d fps', s * 1000, 1 / s))

	end

	ii=ii+1/60
	print(string.format('glyph cache size:  %d KB', tr.rs.glyphs.total_size / 1024))
	print(string.format('glyph count:       %d   ', tr.rs.glyphs.lru.length))
	--self:invalidate()
end

nw:app():run()

tr:free()
