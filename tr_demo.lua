
local tr = require'tr'
local nw = require'nw'
local bundle = require'bundle'
local gfonts = require'gfonts'

local tr = tr.cairo_renderer()

local win = nw:app():window{
	w = 1800, h = 800,
}

local function font(file, name)
	local name = name or assert(file:match('([^\\/]+)%.[a-z]+$')):lower()
	tr:add_font_file(file, name)
	local font = tr:load_font(name)
	print(tr:internal_font_name(font))
end

local function gfont(name)
	local file = assert(gfonts.font_file(tr.font_db:parse_font(name)))
	font(file, name)
end

gfont'open sans'
gfont'open sans italic'
gfont'open sans bold italic'
gfont'open sans 300 italic'
font'media/fonts/NotoColorEmoji.ttf'
font'media/fonts/NotoEmoji-Regular.ttf'
font'media/fonts/EmojiSymbols-Regular.ttf'
font'media/fonts/SubwayTicker.ttf'
font'media/fonts/dotty.ttf'
font'media/fonts/ss-emoji-microsoft.ttf'
font'media/fonts/Hand Faces St.ttf'
font'media/fonts/FSEX300.ttf'
font'media/fonts/amiri-regular.ttf'

tr.font_db:dump()

tr:setfont'NotoColorEmoji, 100'
tr:setfont'NotoEmoji, 109'
tr:setfont'EmojiSymbols, 100'
tr:setfont'SubwayTicker, 15'
tr:setfont'dotty, 32'
tr:setfont'ss-emoji-microsoft, 14'
tr:setfont'Hand Faces St, 14'
tr:setfont'fsex300, 14'
tr:setfont'open sans 200 italic, 200'

local ii=0
function win:repaint()
	local cr = self:bitmap():cairo()
	cr:rgb(0, 0, 0)
	cr:paint()
	cr:rgb(1, 1, 1)

	tr.cr = cr

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

		tr:clear_runs()
		tr:text_run{text = 'Hello!'}
		tr:process_runs()
		--tr:run_text'هذه هي بعض النصوص العربي\nHello there!'
		--tr:run_font'amiri, 50'

		tr:setfont'amiri, 50'
		--tr:shape_text('Hello there!\nهذه هي بعض النصوص العربي')
		tr:shape_text('هذه هي بعض النصوص العربي\nHello there!')
		tr:paint_text(100, 300)
		tr:clear()

	end

	ii=ii+1/60
	self:invalidate()
end

nw:app():run()

tr:free()
