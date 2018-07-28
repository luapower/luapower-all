
local tr = require'tr'
local nw = require'nw'
local bundle = require'bundle'
local gfonts = require'gfonts'
local time = require'time'

local tr = tr()

local win = nw:app():window{
	--w = 1800, h = 800,
	w = 800, h = 400,
}

local function font(file, name)
	local name = name or assert(file:match('([^\\/]+)%.[a-z]+$')):lower()
	tr.rs:add_font_file(file, name)
	local font = tr.rs:load_font(name)
	--print(tr:internal_font_name(font))
end

local function gfont(name)
	local file = assert(gfonts.font_file(tr.rs.font_db:parse_font(name)))
	font(file, name)
end

--gfont'open sans'
--gfont'open sans italic'
--gfont'open sans bold italic'
--gfont'open sans 300 italic'
--font'media/fonts/NotoColorEmoji.ttf'
--font'media/fonts/NotoEmoji-Regular.ttf'
--font'media/fonts/EmojiSymbols-Regular.ttf'
--font'media/fonts/SubwayTicker.ttf'
--font'media/fonts/dotty.ttf'
--font'media/fonts/ss-emoji-microsoft.ttf'
--font'media/fonts/Hand Faces St.ttf'
--font'media/fonts/FSEX300.ttf'
font'media/fonts/amiri-regular.ttf'

--tr.font_db:dump()

--tr.rs:setfont'NotoColorEmoji, 100'
--tr.rs:setfont'NotoEmoji, 109'
--tr.rs:setfont'EmojiSymbols, 100'
--tr.rs:setfont'SubwayTicker, 15'
--tr.rs:setfont'dotty, 32'
--tr.rs:setfont'ss-emoji-microsoft, 14'
--tr.rs:setfont'Hand Faces St, 14'
--tr.rs:setfont'fsex300, 14'
--tr.rs:setfont'open sans 200 italic, 200'

local ii=0
function win:repaint()
	local cr = self:bitmap():cairo()
	cr:identity_matrix()
	cr:rgb(0, 0, 0)
	cr:paint()
	cr:rgb(1, 1, 1)

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

		tr:setfont'NotoColorEmoji,100'
		for i = 1, 10 do
			for j = 1, 10 do
				tr:paint_glyph(tr:load_glyph(i*10+j, i*150, j*150))
			end
		end

	elseif true then

	local t0 = time.clock()
	local n = 1
	local size = 30
	local line_h = 1.5
	for i=1,n do
		--tr.rs:setfont('amiri', nil, nil, size)

		--local s1 = ('gmmI '):rep(1)
		--local s2 = ('fi AV (ثلاثة 1234 خمسة) '):rep(1)
		--local s3 = ('Hebrew (אדםה (adamah))'):rep(1)
		--tr:text_run{text = s1}
		--tr:text_run{text = s2}
		--tr:text_run{text = s3}
		local runs = tr:shape{
			font = 'amiri', font_size = 20,
			--dir = 'rtl',
			--{'A'},
			--{'m mm'},
			{'خمسة ABC ', features = {}, {'abc def \r\r\n\nghi jkl ', font_size = 30}, 'DEFG'},
		}

		--local x = 0
		--local w, h = self:client_size()
		--local y = line_h * size * (i-1)
		local x = 100
		local y = 200
		local w = 550
		local h = 100

		cr:save()
		cr:rectangle(x, y, w, h)
		cr:line_width(1)
		cr:rgb(1, 1, 0)
		cr:stroke()
		cr:restore()

		tr:paint(runs, x, y, w, h, 'right', 'bottom')
		runs:free()
	end
	print( (1 / ((time.clock() - t0) / n))..' fps')

	end

	ii=ii+1/60
	--self:invalidate()
end

nw:app():run()

tr:free()
