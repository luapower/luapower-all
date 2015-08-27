local SG = require'sg_gl'
local winapi = require'winapi'
local gl = require'winapi.gl21'
local glu = require'glu_lua'
local glue = require'glue'

function SG:pm(m)
	print'-----------------------'
	for i=0,3 do print(string.format('%.3f\t%.3f\t%.3f\t%.3f\t', m[i*4+0], m[i*4+1], m[i*4+2], m[i*4+3])) end
end

local frustum = { --2x2x2 cube
	type = 'shape',
	x = -1, y = -1, z = -1, scale = 2,
	'color', 1,1,1,1,
		'line_loop',
			0,1,0, 0,1,1, 1,1,1, 1,1,0, --top
		'line_loop',
			0,0,0, 1,0,0, 1,0,1, 0,0,1, --bottom
		'line_loop',
			1,1,0, 1,1,1, 1,0,1, 1,0,0, --right
		'line_loop',
			0,0,1, 0,1,1, 0,1,0, 0,0,0, --left
	'color', 1,0,0,.3,
		'quads',
			0,0,1, 0,1,1, 1,1,1, 1,0,1, --front
			0,0,0, 1,0,0, 1,1,0, 0,1,0, --back
}

function SG.type:frustum(e)
	gl.glMultMatrixf(glu.gluInvertMatrixf(glu.gluMultMatrixf(e.view.cmatrix, e.view.pmatrix)))
	self:render_object(frustum)
end

function SG.type:teapot(e)
	local glut = require'glut'
	if e.color then
		gl.glColor4d(unpack(e.color))
	else
		gl.glColor4d(1,1,1,1)
	end
	glut.glutSolidTeapot(1)
end

local axes = { --1x1x1 colored axes
	type = 'shape',
	'color', 1,0,0,1, 'lines', 0,0,0, 1,0,0,
	'color', 0,1,0,1, 'lines', 0,0,0, 0,1,0,
	'color', 0,0,1,1, 'lines', 0,0,0, 0,0,1,
}
function SG.type:axes(e)
	self:render_object(axes)
end

local cube = { --1x1x1 colored cube
	type = 'shape',
	x = -.5, y = -.5, z = -.5,
	'color', 0,0,1,.7,
	'quads',
	1,0,1, 1,1,1, 0,1,1, 0,0,1, --front
	0,1,0, 1,1,0, 1,0,0, 0,0,0, --back
	0,1,0, 0,1,1, 1,1,1, 1,1,0, --top
	0,0,0, 1,0,0, 1,0,1, 0,0,1, --bottom
	1,1,0, 1,1,1, 1,0,1, 1,0,0, --right
	0,0,1, 0,1,1, 0,1,0, 0,0,0, --left
}
function SG.type:cube(e)
	self:render_object(cube)
end

if not ... then require'sg_gl_demo' end

