local editor = require'codedit_editor'

--UI API
function editor:setactive(active) end --stub
function editor:focused() end --stub
function editor:focus() end --stub


--input ------------------------------------------------------------------------------------------------------------------

function editor:input(focused, active, key, char, ctrl, shift, alt,
								mousex, mousey, lbutton, rbutton, wheel_delta,
								doubleclicked, tripleclicked, quadrupleclicked, waiting_for_triple_click)

	if not self.view.clip_x then return end --editor has not been rendered yet, input cannot work

	local client_hit = self.view:client_hit_test(mousex, mousey)
	local selection_hit = self.selection:hit_test(mousex, mousey)
	local ln_margin_hit = self.line_numbers_margin:hit_test(mousex, mousey)

	if client_hit and not selection_hit then
		self.player.cursor = 'text'
	end

	if focused then

		local is_input_char = char and not ctrl and not alt and (#char > 1 or char:byte(1) > 31)
		if is_input_char then
			self:insert_char(char)
		elseif key then
			local shortcut = (ctrl and 'ctrl+' or '') .. (alt and 'alt+' or '') .. (shift and 'shift+' or '') .. key
			self:perform_shortcut(shortcut)
		end

	end

	if doubleclicked and client_hit then
		self:select_word_at_cursor()
		self.word_selected = true
	else
		if tripleclicked and client_hit then
			self:select_line_at_cursor()
		elseif not active and lbutton and selection_hit and not waiting_for_triple_click then
			self.moving_selection = true
			self.moving_at_pos = self.selection.line2 == self.selection.line1
			self.moving_mousex = mousex
			self.moving_mousey = mousey
			self.moving_adjusted = false
			self:setactive(true)
		elseif not active and lbutton and (client_hit or ln_margin_hit) and not waiting_for_triple_click then
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


if not ... then require'codedit_demo' end
