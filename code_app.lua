
local ui = require'ui'
local glue = require'glue'

local tablist = ui.tablist:subclass'ce_tablist'

tablist.tab_slant_left = 80
tablist.tab_slant_right = 75

local tab = ui.tab:subclass'ce_tab'

tab.focusable = false

local editbox = ui.editbox:subclass'ce_editbox'

editbox.multiline = true
--editbox.uses_key_ctrl_tab = true --inhibit exiting the editbox with ctrl+tab
--editbox.uses_key_ctrl_shift_tab = true --inhibit exiting the editbox with ctrl+shift+tab
editbox.border_width = 0
editbox.editor = {
	line_numbers = true,
}

ui:style('ce_editbox, ce_editbox :focused', {
	shadow_blur = 0,
	background_color = false,
})

local win = ui:window{
	w = 800,
	h = 500,
	min_cw = 300,
	min_ch = 200,
	--maximized = true,
	frame = false,
	view = {
		border_width = 1,
		border_color = '#111',
		padding = 6,
		padding_right = 12,
	},
}

local tabs = tablist(win)

win.move_layer = tabs

tabs.max_click_chain = 2
function tabs:doubleclick()
	if win.ismaximized then
		win:restore()
	else
		win:maximize()
	end
end

local frame = ui:layer{
	parent = win,
	border_color = '#222',
	border_width = 1,
	corner_radius = 5,
}

function tabs:add_tab(file)

	local editbox = editbox(frame, {
		text = assert(glue.readfile(file)),
		visible = false,
	})

	local tab = self:tab{
		class = tab,
		text = file,
		editbox = editbox,
		selected = true,
	}

	return tab
end

function tab:tab_selected()
	self.editbox.visible = true
	self.editbox:focus()
end

function tab:tab_unselected()
	self.editbox.visible = false
end

function tabs:after_sync()
	tabs.w = win.view.cw
	frame.x = tabs.x
	frame.y = tabs.y2
	frame.w = tabs.w
	frame.h = win.view.ch - tabs.h
	for i,tab in ipairs(self.tabs) do
		local e = tab.editbox
		e.w = tabs.w
		e.h = win.view.ch - tabs.h
	end
end

function tabs:before_draw()
	self:sync()
end


local t1 = tabs:add_tab('code_app.lua')
local t2 = tabs:add_tab('codedit.lua')
local t3 = tabs:add_tab('ui.lua')

function win:client_rect_changed(cx, cy, cw, ch)
	tabs:sync()
end


ui:run()

