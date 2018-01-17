local codedit = require'codedit'
local player = require'cplayer'
local glue = require'glue'
local pp = require'pp'
local winapi = require'winapi'
require'winapi.filedialogs'
require'winapi.monitor'

player.continuous_rendering = false
player.show_magnifier = false

--config
player.key_bindings = {
	['ctrl+N'] = 'new_tab',
	['ctrl+O'] = 'open_file',
	['ctrl+W'] = 'close_tab',
	['ctrl+tab'] = 'next_tab',
	['ctrl+shift+tab'] = 'prev_tab',
	['ctrl+S'] = 'save_file',
	['ctrl+shift+S'] = 'save_file_as',
	--['f11'] = 'toggle_full_screen',
	--['F5'] = 'run',
}

player.session_file = 'x:/work/lua-files' .. '/.codedit_session.lua'

--state
player.tabs = {}
player.active_tab = nil
player.config = nil

function player:load_config(filename)
	if glue.canopen(filename) then
		return assert(loadfile(filename))()
	end
end

function player:load_config_files()
	local local_config = self:load_config('.codedit_conf.lua')
	local user_config = self:load_config(os.getenv('USERPROFILE') .. '/.codedit_conf.lua')
	local global_config --TODO: winapi.registry
	player.config = glue.update({}, global_config, user_config, local_config)
end

function player:perform_shortcut(shortcut, ...)
	local command = self.key_bindings[shortcut]
	if command and self[command] then
		self[command](self)
		return true
	end
	return false
end

function player:tabname(filename)
	return (filename and filename:match('[%\\%/]([^%\\%/]+)$')) or 'Untitled'
end

function player:new_tab(filename, i)
	i = i or (self.active_tab or #self.tabs) + 1

	local tabname = self:tabname(filename)

	local text = filename and glue.canopen(filename) and glue.readfile(filename) or ''

	local ext = filename and filename:match'%.([^%.]+)$'
	local config
	if ext and self.config.filetypes[ext] then
		config = glue.update({}, self.config, self.config.filetypes[ext])
		glue.merge(config.view, self.config.view)
		glue.merge(config.cursor, self.config.cursor)
	else
		config = self.config
	end

	local editor = self:code_editor{
		id = 'editor_' .. i,
		text = text,
		cursor = config.cursor,
		view = glue.merge({
			x = 0, y = 26,
			w = self.w,
			h = self.h,
			font_file     = config.font_file,
			eol_markers   = config.eol_markers,
			minimap       = config.minimap,
		}, config.view),
	}

	glue.update(editor.key_bindings, self.config.key_bindings)
	glue.update(self.key_bindings, self.config.key_bindings)

	--override shortcut handling with local methods
	local parent = self
	function editor:perform_shortcut(shortcut, ...)
		if not parent:perform_shortcut(shortcut, ...) then
			codedit.perform_shortcut(self, shortcut, ...)
		end
	end

	if #self.tabs == 1
		and not self.tabs[1].filename
		and #self.tabs[1].editor.buffer.lines == 1
		and #self.tabs[1].editor.buffer.lines[1] == 0
		and not self.tabs[1].editor.buffer.changed.file
	then
		self:destroy_tab(1)
		i = 1
	end

	table.insert(self.tabs, i, {
		name = tabname,
		filename = filename,
		editor = editor,
	})
	self.active_tab = i

	return editor
end

function player:open_file()
	if self._opening then return end
	self._opening = true
	local ok, info = winapi.GetOpenFileName{
		filter = {'All Files','*.*'},
		flags = '',
		hwndOwner = self.window.hwnd,
	}
	self._opening = nil
	if ok then
		self:new_tab(info.filepath)
	end
end

function player:destroy_tab(i)
	table.remove(self.tabs, i)
end

function player:close_tab(i)
	i = i or self.active_tab
	self:save_file(i)
	self:destroy_tab(i)
	self.active_tab = math.min(i, #self.tabs)
	if #self.tabs == 0 then
		self:new_tab()
	end
end

function player:next_tab()
	self.active_tab = (((self.active_tab + 1) - 1) % #self.tabs) + 1
end

function player:prev_tab()
	self.active_tab = (((self.active_tab - 1) - 1) % #self.tabs) + 1
end

function player:save_state()
	local filename = self.session_file
	local state = {
		tabs = {},
		active_tab = self.active_tab,
		fullscreen = self.fullscreen,
	}
	for i, tab in ipairs(self.tabs) do
		if tab.filename then
			local tab_state = {filename = tab.filename, editor = {}}
			tab.editor:save_state(tab_state.editor)
			table.insert(state.tabs, tab_state)
		end
	end
	pp.save(filename, state)
end

function player:load_state()
	assert(#self.tabs == 0)
	local filename = self.session_file
	if glue.canopen(filename) then
		local state = assert(loadfile(filename))()
		for i,tab_state in ipairs(state.tabs) do
			if glue.canopen(tab_state.filename, 'w') then
				local editor = self:new_tab(tab_state.filename)
				editor:load_state(tab_state.editor)
			end
		end
		self.active_tab = math.min(state.active_tab or 1, #self.tabs)
		self.fullscreen = state.fullscreen
	end
end

function player:save_file(i)
	i = i or self.active_tab
	local tab = self.tabs[i]
	if tab.filename then
		if not tab.editor.buffer.changed.file then return end
		tab.editor:save(tab.filename)
		tab.editor.buffer.changed.file = false
		self:invalidate()
	else
		self:save_file_as(i)
	end
end

function player:save_file_as(i)
	i = i or self.active_tab
	local tab = self.tabs[i]

	if self._saving then return end
	self._saving = true
	local ok, info = winapi.GetSaveFileName{
		filter = {'All Files','*.*'},
		flags = 'OFN_OVERWRITEPROMPT | OFN_CREATEPROMPT',
		hwndOwner = self.window.hwnd,
	}
	self._saving = nil

	if ok then
		local filename = info.filepath
		tab.filename = filename
		self.tabs[self.active_tab] = self:tabname(filename)
		tab.editor:save(tab.filename)
		tab.editor.buffer.changed.file = false
		self:invalidate()
	end
end

function player:toggle_full_screen()
	if self.fullscreen then
		self.window.frame = true
		self.window.border = true
		self.window:restore()
 	else
		self.window:maximize()
		self.window.frame = false
		self.window.border = false
	end
	self.fullscreen = not self.fullscreen
	self.panel:move(0, 0, self.window.client_w, self.window.client_h)
end

function player:on_render(cr)

	if not self.initialized then

		self:load_config_files()

		self:load_state()

		if self.fullscreen then
			self.fullscreen = false
			self:toggle_full_screen()
			self.initialized = 1
			return
		end
	end
	if not self.initialized or self.initialized == 1 then
		if #self.tabs == 0 then
			self:new_tab()
		end
		self.initialized = true
	end

	if self.key == 'f11' then
		self:toggle_full_screen()
		return
	end

	local tabs = {}
	for i,tab in ipairs(self.tabs) do
		tabs[i] = tab.name .. (self.tabs[i].editor.buffer.changed.file and '*' or '')
	end

	self.active_tab = self:tablist{id = 'tabs', x = 0, y = 0, w = self.w, h = 26, font_size = 12, font_face = 'Fixedsys',
												values = tabs, selected = self.active_tab}

	local editor = self.tabs[self.active_tab].editor
	editor.view.x = 0
	editor.view.y = 26
	editor.view.w = self.w
	editor.view.h = self.h - 26

	self:code_editor(editor)
end

function player:on_close()
	self:save_state()
end

player:play()

