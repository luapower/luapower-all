--screen: window manager for hit-testing, reordering, snapping, and rendering overlapping windows.
local app = require'cplayer'
local box = require'box2d'

local screen = {
	snapping = true,
	snap_distance = 20,
	move_snapped = true,
}

function screen:new(t)
	self = setmetatable(t or {}, {__index = self})
	self.windows = {} --{window1,...} in reverse z_order
	return self
end

function screen:add(window, z_order)
	z_order = z_order or 0
	local index = #self.windows - z_order + 1
	index = math.min(math.max(index, 1), #self.windows + 1)
	table.insert(self.windows, index, window)
end

function screen:indexof(target_window)
	for i,window in ipairs(self.windows) do
		if window == target_window then
			return i
		end
	end
end

function screen:top_window()
	for i = #self.windows, 1, -1 do
		local win = self.windows[i]
		if win.visible then
			return win
		end
	end
end

function screen:remove(window)
	table.remove(self.windows, self:indexof(window))
end

function screen:bring_to_front(window)
	self:remove(window)
	self:add(window, 0)
end

function screen:send_to_back(window)
	self:remove(window)
	self:add(window, 1/0)
end

function screen:render()

	if not self.app.active and self.app.lpressed then
		for i = #self.windows, 1, -1 do
			local window = self.windows[i]
			if self.app:hotbox(window:getbox()) then
				self:bring_to_front(window)
				break
			end
		end
	end

	for i,window in ipairs(self.windows) do
		window:render()
	end
end

function screen:hotbox(target_window, x, y, w, h)
	for i = #self.windows, 1, -1 do
		local window = self.windows[i]
		if window == target_window then
			return window:_hotbox(x, y, w, h)
		elseif window:_hotbox(window:getbox()) then
			break
		end
	end
	return false
end

function screen:snapped_windows(win0)
	self._target_win = win0
	self._next_snapped_win = self._next_snapped_win or
		coroutine.wrap(function()
			while true do
				for i, win in ipairs(self.windows) do
					if win.visible and win ~= self._target_win then
						local x, y, w, h = self._target_win:getbox()
						local snapped, left, top, right, bottom = box.snapped_edges(1, x, y, w, h, win:getbox())
						if snapped then
							coroutine.yield(win, left, top, right, bottom)
						end
					end
				end
				coroutine.yield()
			end
		end)
	return self._next_snapped_win
end

function screen:_snap_rectangles(win0) --internal cached iterator for enumerating rectangles to snap against
	self._target_win = win0
	local t = {}
	for i = #self.windows, 1, -1 do
		local win = self.windows[i]
		if win.visible and win ~= self._target_win then
			local x, y, w, h = win:getbox()
			t[#t+1] = {x = x, y = y, w = w, h = h}
		end
	end
	t[#t+1] = {x = self.x, y = self.y, w = self.w, h = self.h}
	return t
end

function screen:setpos(win, x, y)
	if self.snapping then
		local _, _, w, h = win:getbox()
		win:_setpos(
			box.snap_pos(
				self.snap_distance,
				x, y, w, h,
				self:_snap_rectangles(win),
				true))
	else
		win:_setpos(x, y)
	end
end

function screen:setbox(win, x, y, w, h)
	if self.snapping then
		win:_setbox(
			box.snap_edges(
				self.snap_distance,
				x, y, w, h,
				self:_snap_rectangles(win),
				true))
	else
		win:_setbox(x, y, w, h)
	end
end

function screen:set_minimized(win, minimized)
	if self.move_snapped and minimized ~= win.minimized then

		--gather windows snapped to the bottom
		local t = {}
		for win, left, top, right, bottom in self:snapped_windows(win) do
			if bottom then
				t[win] = true
			end
		end

		win:_set_minimized(minimized)

		if next(t) then
			--move them to win's bottom
			local x, y, w, h = win:getbox()
			for win in pairs(t) do
				local x1, y1 = win:getbox()
				win:setpos(x1, y + h)
			end

			--trigger a repaint, since other windows outside of the target window changed
			self.app:invalidate()
		end
	else
		win:_set_minimized(minimized)
	end
end

function app:screen(t)
	return screen:new(t)
end


if not ... then require'cplayer.toolbox_demo' end
