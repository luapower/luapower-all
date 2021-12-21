--retained mode gui manager
local layerlist = require'cplayer.layerlist'
local box = require'box2d'

local rmgui = {}

function rmgui:new()
	self = setmetatable({}, {__index = self})
	self.widgets = {}
	self.layers = layerlist:new()
	self.mouse = {x = 0, y = 0, lbutton = false, rbutton = false, locked = false}
	self.keys = {locked = false}
	return self
end

function rmgui:add_widget(widget, index)
	table.insert(self.widgets, index or #self.widgets + 1, widget)
	widget.index = index
	self.layers:add(widget)
end

function rmgui:remove_widget(widget)
	table.remove(self.widgets, widget.index)
	self.layers:remove(widget)
	if self.mouse.locked == widget then
		self.mouse.locked = false
	end
	if self.keys.locked == widget then
		self.keys.locked = false
	end
end

function rmgui:bring_to_front(widget)
	self.layers:bring_to_front(widget)
end

function rmgui:send_to_back(widget)
	self.layers:send_to_back(widget)
end

function rmgui:render(cx)
	self.layers:render(cx)
end

function rmgui:lock_mouse(widget) self.mouse.locked = widget end
function rmgui:unlock_mouse() self.mouse.locked = false end
function rmgui:lock_keys(widget) self.keys.locked = widget end
function rmgui:unlock_keys() self.keys.locked = false end

function rmgui:update(event, ...)
	if event == 'mouse_move' then
		self.mouse.x, self.mouse.y = ...
		if not self.mouse.locked then
			local old_hot_widget = self.hot_widget
			local new_hot_widget = self.layers:hit(self.mouse.x, self.mouse.y)
			self.hot_widget = nil
			if old_hot_widget and old_hot_widget ~= new_hot_widget then
				old_hot_widget:update(self, 'mouse_leave', ...)
			end
			if new_hot_widget and old_hot_widget ~= new_hot_widget then
				new_hot_widget:update(self, 'mouse_enter', ...)
			end
			self.hot_widget = new_hot_widget
			if new_hot_widget then
				self.hot_widget:update(self, event, ...)
			end
		end
	elseif event:match'^mouse_' then
		if self.hot_widget then
			self.hot_widget:update(self, event, ...)
		end
	end
end


if not ... then

local player = require'cplayer'

local btn1 = {
	x = 100,
	y = 100,
	w = 100,
	h = 26,
	getbox = function(self)
		return self.x, self.y, self.w, self.h
	end,
	hit = function(self, mx, my)
		return box.hit(mx, my, self:getbox())
	end,
	render = function(self, app)
		local x, y, w, h = self:getbox()
		app:rect(x, y, w, h, self.pressed and 'selected_bg' or self.hot and 'hot_bg' or 'normal_bg')
		if self.stopwatch and not self.stopwatch:finished() then
			self:circle(x + w / 2, y + h / 2, self.stopwatch:progress() * 100, 'normal_bg')
		end
	end,
	update = function(self, app, event, ...)
		--print(event, ...)
		if event == 'mouse_enter' then
			self.hot = true
			self.stopwatch = player:stopwatch(100)
		elseif event == 'mouse_leave' then
			self.hot = false
			self.stopwatch = player:stopwatch(100)
		elseif event == 'mouse_lbutton_down' then
			self.pressed = true
		elseif event == 'mouse_lbutton_double_click' then
			self.pressed = true
			if self.on_double_click then
				self:on_double_click()
			end
		elseif event == 'mouse_lbutton_up' then
			self.pressed = false
			if self.on_click then
				self:on_click()
			end
		end
	end,
}

function player:on_render(cr)
	if self.init then
		self.rmgui:add_widget(btn1)

		function btn1.on_click(btn1)
			--btn1.stopwatch = self:stopwatch(100)
		end
	end
end

player:play()

end

return rmgui
