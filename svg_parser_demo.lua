local glue = require'glue'
local cairo = require'cairo'
--require'scenegraph.cairopng'
local winapi = require'winapi'
require'winapi.windowclass'
local CairoSGPanel = require'winapi.cairosgpanel'

local main = winapi.Window{
	autoquit = true,
	visible = false,
	title = cairo.version_string(),
}

local panel = CairoSGPanel{
	parent = main,
	anchors = {left=true,right=true,top=true,bottom=true},
	w = main.client_w,
	h = main.client_h,
}

local function dir(d)
	local f = io.popen('ls -1 '..d)
	return glue.collect(f:lines())
end

local files = dir'media/svg/*.svg'
local i = 133 --77, 87, 119, 133 (leon)

local marker = {type = 'shape', path = {'rect', 0, 0, 100, 100}, stroke = {type = 'color', 0, 0, 0}}

--pp(#bpath)

local arcs01 = {type = 'svg', file = {string = [[
<?xml version="1.0" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"
  "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg width="12cm" height="5.25cm" viewBox="0 0 1200 400"
     xmlns="http://www.w3.org/2000/svg" version="1.1">
  <title>Example arcs01 - arc commands in path data</title>
  <desc>Picture of a pie chart with two pie wedges and
        a picture of a line with arc blips</desc>
  <rect x="1" y="1" width="1198" height="398"
        fill="none" stroke="blue" stroke-width="1" />

  <path d="M300,200 h-150 a150,150 0 1,0 150,-150 z"
        fill="red" stroke="blue" stroke-width="5" />

  <path d="M275,175 v-150 a150,150 0 0,0 -150,150 z"
        fill="yellow" stroke="blue" stroke-width="5" />

  <path d="M600,350 l 50,-25
           a25,25 -30 0,1 50,-25 l 50,-25
           a25,50 -30 0,1 50,-25 l 50,-25
           a25,75 -30 0,1 50,-25 l 50,-25
           a25,100 -30 0,1 50,-25 l 50,-25"
        fill="none" stroke="red" stroke-width="5"  />
</svg>
]]}}

local arcs02 = {type = 'svg', file = {string = [[
<?xml version="1.0" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"
  "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg width="12cm" height="5.25cm" viewBox="0 0 1200 525" version="1.1"
     xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
  <title>Example arcs02 - arc options in paths</title>
  <desc>Pictures showing the result of setting
        large-arc-flag and sweep-flag to the four
        possible combinations of 0 and 1.</desc>
  <g font-family="Verdana" >
    <defs>
      <g id="baseEllipses" font-size="20" >
        <ellipse cx="125" cy="125" rx="100" ry="50"
                 fill="none" stroke="#888888" stroke-width="2" />
        <ellipse cx="225" cy="75" rx="100" ry="50"
                 fill="none" stroke="#888888" stroke-width="2" />
        <text x="35" y="70">Arc start</text>
        <text x="225" y="145">Arc end</text>
      </g>
    </defs>
    <rect x="1" y="1" width="1198" height="523"
          fill="none" stroke="blue" stroke-width="1" />

    <g font-size="30" >
      <g transform="translate(0,0)">
        <use xlink:href="#baseEllipses"/>
      </g>
      <g transform="translate(400,0)">
        <text x="50" y="210">large-arc-flag=0</text>
        <text x="50" y="250">sweep-flag=0</text>
        <use xlink:href="#baseEllipses"/>
        <path d="M 125,75 a100,50 0 0,0 100,50"
              fill="none" stroke="red" stroke-width="6" />
      </g>
      <g transform="translate(800,0)">
        <text x="50" y="210">large-arc-flag=0</text>
        <text x="50" y="250">sweep-flag=1</text>
        <use xlink:href="#baseEllipses"/>
        <path d="M 125,75 a100,50 0 0,1 100,50"
              fill="none" stroke="red" stroke-width="6" />
      </g>
      <g transform="translate(400,250)">
        <text x="50" y="210">large-arc-flag=1</text>
        <text x="50" y="250">sweep-flag=0</text>
        <use xlink:href="#baseEllipses"/>
        <path d="M 125,75 a100,50 0 1,0 100,50"
              fill="none" stroke="red" stroke-width="6" />
      </g>
      <g transform="translate(800,250)">
        <text x="50" y="210">large-arc-flag=1</text>
        <text x="50" y="250">sweep-flag=1</text>
        <use xlink:href="#baseEllipses"/>
        <path d="M 125,75 a100,50 0 1,1 100,50"
              fill="none" stroke="red" stroke-width="6" />
      </g>
    </g>
  </g>
</svg>
]]}}

local svgfile = {type = 'svg', file = {path = 'media/svg/leon.svg'}}

local scene = {type = 'group', x = 600, --y = 100,
	{type = 'color',1,1,1},
	svgfile,
	{type = 'group', x = -500, arcs01},
	{type = 'group', x = -500, y = 300, arcs02},
}

local zoom = 1

local stroke_extents_stroke = {type = 'color', 0, 0, 1, 0.5}
local fill_extents_stroke = {type = 'color', 1, 0, 0, 0.5}

function panel:on_render()
	scene.scale = zoom
	self.scene_graph.stroke_extents_stroke = stroke_extents_stroke
	self.scene_graph.fill_extents_stroke = fill_extents_stroke
	self.scene_graph:render(scene)
	self.scene_graph.cache:clear()
end

function main:on_mouse_wheel(x, y, buttons, delta)
	zoom = zoom + delta/120/10
	panel:invalidate()
end

--panel:settimer(1000, panel.invalidate)

main:show()

os.exit(winapi.MessageLoop())

