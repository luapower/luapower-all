--TODO: this crashes
local player = require'cplayer'
local winapi = require'winapi'
require'winapi.filedialogs'

local ffi = require'ffi'
ffi.cdef[[
HRESULT CoInitialize(LPVOID pvReserved);
HRESULT CoInitializeEx(LPVOID pvReserved, DWORD dwCoInit);
]]

local ole = ffi.load'Ole32'
ole.CoInitializeEx(nil, 2)

function player:filebox(t)

	local id = assert(t.id, 'id missing')
	local x, y, w, h = self:getbox(t)
	local filename = t.filename or 'browse...'
	local btn_w = h * 1.5

	filename = self:editbox{id = id .. '_edit', x = x, y = y, w = w - btn_w, h = h, text = filename, readonly = true}

	if self:button{
		id = id .. '_btn',  x = x + w - btn_w, y = y, w = btn_w, h = h,
		text = '...', cut = 'left'
	} then
		local ok, info = winapi.GetOpenFileName{
			filter = {'All Files','*.*'},
			flags = 'OFN_FILEMUSTEXIST',
			hwndOwner = self.window.hwnd,
		}
		if ok then
			filename = info.filepath
		end
	end

	return filename
end


if not ... then require'cplayer.widgets_demo' end
