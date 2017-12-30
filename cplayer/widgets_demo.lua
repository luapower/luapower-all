local player = require'cplayer'
local glue = require'glue'
local boxlayer = require'cplayer.boxlayer'
local ffi = require'ffi'

local t = {
	tab = 1,
	text1 = 'edit me',
	text2 = 'edit me too as I am a very long string that wants to be edited',
	text3 = '"this is me quoting myself" - me',
	percent = 50,
	fruit = 'cherries',
	theme = 'dark',
}

local layer = glue.inherit({x = 50, y = 20, w = 280, h = 300}, boxlayer)

function player:on_render(cr)

	self.layers:add(layer)

	local cpx, cpy = 10, 10

	local rx, ry, rw, rh = cpx, cpy, 260, 120
	t.vx = self:hscrollbar{id = 'hs', x = rx, y = ry + rh, w = rw, h = 16, size = rw * 2, i = t.vx, autohide = false}
	t.vy = self:vscrollbar{id = 'vs', x = rx + rw, y = ry, w = 16, h = rh, size = rh * 2, i = t.vy, autohide = true}

	cr:rectangle(rx, ry, rw, rh)
	cr:clip()
	cr:rgba(1,1,1,0.1)
	cr:paint()

	if self:button{id = 'apples_btn', x = rx - t.vx, y = ry - t.vy, w = 100, h = 24, text = 'go apples!'} then
		t.fruit = 'apples'
	end

	if self:button{id = 'bannanas_btn', x = rx - t.vx, y = ry + 30 - t.vy, w = 100, h = 24, text = 'go bannanas!'} then
		t.fruit = 'bannanas'
	end

	if self:button{id = 'undecided_btn', x = rx - t.vx, y = ry + 2*30 - t.vy, w = 100, h = 24, text = 'meh, dunno...'} then
		t.fruit = nil
	end

	assert(not self:button{id = 'undecided_btn', x = rx - t.vx + 110, y = ry + 30 - t.vy, w = 100, h = 24,
			text = 'disabled', enabled = false})

	t.fruit = self:mbutton{id = 'fruits_btn', x = rx - t.vx, y = ry + 3*30 - t.vy, w = 260, h = 24,
									values = {'apples', 'bannanas', 'cherries'}, selected = t.fruit}

	cr:reset_clip()

	cpy = cpy + rh + 16 + 10

	t.text1 = self:editbox{id = 'ed1', x = 10, y = cpy, w = 200, h = 24, text = t.text1, next_tab = 'ed2', prev_tab = 'ed3'}
	cpy = cpy + 24 + 10
	t.text2 = self:editbox{id = 'ed2', x = 10, y = cpy, w = 200, h = 24, text = t.text2, next_tab = 'ed3', prev_tab = 'ed1'}
	cpy = cpy + 24 + 10
	t.text3 = self:editbox{id = 'ed3', x = 10, y = cpy, w = 200, h = 24, text = t.text3, next_tab = 'ed1', prev_tab = 'ed2'}
	cpy = cpy + 24 + 10

	t.percent = self:slider{id = 'slider', x = 10, y = cpy, w = 200, h = 24, size = 100, i = t.percent, i1 = 100, step = 10}
	cpy = cpy + 24 + 10

	local theme_names = glue.keys(self.themes); table.sort(theme_names)
	t.theme = self:mbutton{id = 'theme_btn', x = 10, y = cpy, w = 120, h = 24, values = theme_names, selected = t.theme}
	self.theme = self.themes[t.theme]
	cpy = cpy + 24 + 10

	if ffi.abi'win' then
		t.filename = self:filebox{id = 'filebox', x = 10, y = cpy, w = 200, h = 24, filename = t.filename}
	end
	cpy = cpy + 24 + 10

	local menu = self:combobox{id = 'combo', x = 10, y = cpy, w = 100, h = 24, items = {'item1', 'item2', 'item3'},
										selected = t.combo_item}
	cpy = cpy + 24 + 10

	t.tab = self:tablist{id = 'tabs', x = 10, y = cpy, w = 200, h = 24,
								values = {'tab1', 'tab2', 'tab3'}, selected = t.tab}
	cpy = cpy + 24 + 10

	t.menu_item = self:menu{id = 'menu', x = 10, y = cpy, w = 100, h = 100,
										items = {'item1', 'item2', 'item3'}, selected = t.menu_item}
	cpy = cpy + 100 + 10

	if menu then
		menu.selected = t.combo_item
		local clicked
		t.combo_item, clicked = self:menu(menu)
		if clicked then t.cmenu = nil end
	end

	local x, y, w, h
	t.sb_cx, t.sb_cy, x, y, w, h =
		self:scrollbox{id = 'scrollbox', x = 300, y = 10, w = 200, h = 200,
							cx = t.sb_cx, cy = t.sb_cy, cw = 500, ch = 500}
	cr:save()
	cr:rectangle(x, y, w, h)
	cr:clip()
	cr:translate(t.sb_cx, t.sb_cy)
	self:rect(300, 10, 500, 500, 'normal_bg', 'normal_border', 10)
	cr:translate(-t.sb_cx, -t.sb_cy)
	cr:restore()

	t.node13 = t.node13 or
			{name = 'level1.3',
				'level2.1',
				'level2.2',
			}

	t.tree_state =
	self:treeview{id = 'tree', x = 530, y = 220, w = 400, h = 200,
		nodes = {
			'level1.1',
			'level1.2',
			t.node13,
			'level1.4',
		},
		state = t.tree_state or {
			open_nodes = {[t.node13] = true},
		},
	}

	t.splitx = self:vsplitter{id = 'split', x = t.splitx or 950, y = 10, w = 6, h = 300}
end

player.continuous_rendering = false

return player:play()


