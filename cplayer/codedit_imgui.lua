
--codedit IMGUI integration

local codedit = require'codedit'
local view = codedit.view
local editor = codedit.editor

--draw a scrollbox widget with the clipping rect (x, y, w, h) and the client
--rect (cx, cy, cw, ch). return the new cx, cy, adjusted from user input
--and other scrollbox constraints, followed by the clipping rect.
--the client rect is relative to the clipping rect of the scrollbox (which
--can be different than its outside rect). this stub implementation is
--equivalent to a scrollbox that takes no user input, has no margins, and has
--invisible scrollbars.
function view:imgui_draw_scrollbox(x, y, w, h, cx, cy, cw, ch)
	return cx, cy, x, y, w, h
end

function view:imgui_draw()

	self:sync()

	local client_w, client_h = self:client_size()
	local margins_w = self:margins_width()

	self.scroll_x, self.scroll_y,
	self.clip_x, self.clip_y, self.clip_w, self.clip_h =
		self:draw_scrollbox(
			self.x + margins_w, self.y,
			self.w - margins_w, self.h,
			self.scroll_x, self.scroll_y,
			client_w, client_h)

	for i,margin in ipairs(self.margins) do
		self:draw_margin(margin)
	end
	self:draw_client()
end

function editor:imgui_input(focused, active, key, char, ctrl, shift, alt,
	mousex, mousey, lbutton, rbutton, wheel_delta,
	doubleclicked, tripleclicked, quadrupleclicked, waiting_for_triple_click)

	--scrollbox has not been rendered yet, input cannot work
	if not self.view.clip_x then return end

	local client_hit = self.view:client_hit_test(mousex, mousey)
	local selection_hit = self.selection:hit_test(mousex, mousey)
	local ln_margin_hit = self.line_numbers_margin:hit_test(mousex, mousey)

	if client_hit and not selection_hit then
		self.player.cursor = 'text'
	end

	if focused then

		local is_input_char = char and not ctrl and not alt
			and (#char > 1 or char:byte(1) > 31)

		if is_input_char then
			self:insert_char(char)
		elseif key then
			local shortcut =
				(ctrl  and 'ctrl+'  or '') ..
				(alt   and 'alt+'   or '') ..
				(shift and 'shift+' or '') .. key
			self:perform_shortcut(shortcut)
		end

	end

	if doubleclicked and client_hit then
		self:select_word_at_cursor()
		self.word_selected = true
	else
		if tripleclicked and client_hit then
			self:select_line_at_cursor()
		elseif not active and lbutton and selection_hit
			and not waiting_for_triple_click
		then
			self.moving_selection = true
			self.moving_at_pos = self.selection.line2 == self.selection.line1
			self.moving_mousex = mousex
			self.moving_mousey = mousey
			self.moving_adjusted = false
			self:setactive(true)
		elseif not active and lbutton and (client_hit or ln_margin_hit)
			and not waiting_for_triple_click
		then
			self:move_cursor_to_coords(mousex, mousey)
			self:setactive(true)
		elseif active == self.id then
			if lbutton then
				if self.moving_selection then
					if self.moving_at_pos then
						--TODO: finish moving sub-line selection with the mouse
					elseif not self.moving_adjusted and
						(math.abs(mousex - self.moving_mousex) >= 6 or
						 math.abs(mousey - self.moving_mousey) >= 6)
					then
						self.selection:set_to_line_range()
						self.selection:reverse()
						self.cursor:move_to_selection(self.selection)
						self.moving_adjusted = true
					end
					if self.moving_adjusted then
						--TODO: finish moving multiline selection with the mouse
					end
				else
					local mode = alt and 'select_block' or 'select'
					self:move_cursor_to_coords(mousex, mousey, mode)
				end
			else
				if self.moving_selection and not self.moving_adjusted then
					self:move_cursor_to_coords(mousex, mousey)
				end
				self.moving_selection = nil
				self:setactive(false)
			end
		end
		self.word_selected = false
	end

end
