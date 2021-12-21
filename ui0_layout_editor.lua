
--UI Layout Editor widgets.
--Written by Cosmin Apreutesei.

if not ... then require'pfglab3_app'; return end

local ui = require'ui0'
local box2d = require'box2d'

--direct manipulation widget editor

local editor = ui.layer:subclass'editor'
ui.editor = editor

--keep the editor layer on top of all other layers.
function ui.layer:override_add_layer(inherited, layer, index)
	inherited(self, layer, index)
	if self == self.window.view and self.window.editor then
		self:move_layer(self.window.editor, 1/0)
	end
end

function editor:before_set_window()
	if self.window then
		self.window.editor = nil
	end
end

function editor:after_set_window(win)
	if win then
		win.editor = self
	end
end

function editor:after_init()
	self.window.editor = self
end

--drawing

--editor.background_color = '#3338'

function editor:before_sync()
	self.w = self.window.view.cw
	self.h = self.window.view.ch
end

function editor:dot(cr, x, y, w, h)
	w = w or 4
	h = h or 4
	cr:new_path()
	cr:rectangle(x - w/2, y - h/2, w, h)
	cr:fill()
end

function editor:walk_layer(cr, layer, func, ...)
	if not layer.visible then return end
	cr:save()
	cr:matrix(layer:cr_abs_matrix(cr))
	func(self, cr, layer, ...)
	self:walk_children(cr, layer, func, ...)
	cr:restore()
end

function editor:walk_children(cr, layer, func, ...)
	local cx, cy = layer:padding_pos()
	cr:translate(cx, cy)
	for i = 1, #layer do
		self:walk_layer(cr, layer[i], func, ...)
	end
	cr:translate(-cx, -cy)
end

function editor:draw_target(cr, layer)
	if not layer.visible then return false end
	if not layer.iswidget then return false end
	cr:rgba(self.ui:rgba'#888')

	self:dot(cr, 0, 0)
	self:dot(cr, 0, layer.h)
	self:dot(cr, layer.w, 0)
	self:dot(cr, layer.w, layer.h)

	cr:new_path()
	cr:rectangle(0, 0, layer.w, layer.h)
	cr:line_width(1)
	if layer == self.hot_widget then
		cr:stroke_preserve()
		cr:rgba(self.ui:rgba'#f936')
		cr:fill()
	else
		cr:stroke()
	end
end

function editor:before_draw_content(cr)
	self:walk_layer(cr, self.window.view, self.draw_target)
end

--hit testing

function editor:hit_test_target_children(cr, layer, x, y)
	for i = #layer, 1, -1 do
		if self:hit_test_target(cr, layer[i], x, y) then
			return true
		end
	end
end

function editor:hit_test_target(cr, layer, x, y)
	if layer == self then return end
	if not layer.visible then return end
	if not (layer.iswidget or layer == layer.window.view) then return end
	local x, y = layer:from_parent(x, y)
	if self:hit_test_target_children(cr, layer, x, y) then
		return true
	elseif box2d.hit(x, y, 0, 0, layer.cw, layer.ch) then
		self.hot_widget = layer
		self:invalidate()
		return true
	end
end

function editor:hit_test(x, y, reason)
	if not self.visible then return end
	if reason ~= 'activate' then return end
	self.hot_widget = false
	if self:hit_test_target(self.window.cr, self.window.view, x, y) then
		return self, 'widget'
	end
end

function editor:click()
	if not self.hot_widget then return end
	self.visible = false
end

return editor
