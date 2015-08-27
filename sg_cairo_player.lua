local winapi = require'winapi'
require'winapi.windowclass'
local SGPanel = require'winapi.cairosgpanel'
local cairo = require'cairo'

local main = winapi.Window{
	autoquit = true,
	visible = false,
	--state = 'maximized',
}
local panel = SGPanel{
	parent = main, w = main.client_w, h = main.client_h,
	anchors = {left=true,right=true,top=true,bottom=true}
}
local scene = {type = 'group', scale = 1}

function main:on_mouse_wheel(x, y, buttons, delta)
	scene.cx = panel.client_w / 2
	scene.cy = panel.client_h / 2 - 500
	scene.scale = scene.scale + delta/120/10
	panel:invalidate()
end

local player = {}

function panel:on_render()
	player.scene_graph = self.scene_graph
	player:on_render()
end

function panel:on_mouse_move(x, y, buttons)
	if not self.scene_graph then return end
	self.scene_graph.mouse_x = x
	self.scene_graph.mouse_y = y
	self.scene_graph.mouse_buttons = buttons
	--scene.scale = 1 + (x * 10 / 1920)
	self:invalidate()
end

panel.on_mouse_move = panel.on_mouse_move
panel.on_mouse_over = panel.on_mouse_move
panel.on_mouse_leave = panel.on_mouse_move
panel.on_lbutton_double_click = panel.on_mouse_move
panel.on_lbutton_down = panel.on_mouse_move
panel.on_lbutton_up = panel.on_mouse_move
panel.on_mbutton_double_click = panel.on_mouse_move
panel.on_mbutton_down = panel.on_mouse_move
panel.on_mbutton_up = panel.on_mouse_move
panel.on_rbutton_double_click = panel.on_mouse_move
panel.on_rbutton_down = panel.on_mouse_move
panel.on_rbutton_up = panel.on_mouse_move
panel.on_xbutton_double_click = panel.on_mouse_move
panel.on_xbutton_down = panel.on_mouse_move
panel.on_xbutton_up = panel.on_mouse_move
panel.on_mouse_wheel = panel.on_mouse_move
panel.on_mouse_hwheel = panel.on_mouse_move

panel:settimer(1/60, panel.invalidate)

function player:play()
	main:show()
	os.exit(winapi.MessageLoop())
end

function player:render(user_scene)
	scene[1] = user_scene
	panel.scene_graph:render(scene)
	main.title = string.format('Cairo %s', cairo.cairo_version_string())
end

function player:hit_test(x, y, user_scene)
	scene[1] = user_scene
	return panel.scene_graph:hit_test(x, y, scene)
end

function player:measure(e)
	return panel.scene_graph:measure(e)
end

return player
