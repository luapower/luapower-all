
if not ... then require'imgui_demo'; return end

return function(self)
	local cr = self.cr

	--self.show_magnifier = false

	self:setmargin(5, 5)

	cr:translate(0.5, 0.5)

	--self.default.default_font =
--'akronim,36'
--'DejaVu Sans,14'

	--cr:font_face('Fixedsys')
	--cr:font_size(12)
	--cr:rgb(1, 1, 1)

	--[[
	self:begin_content_box'h'
		self:begin_content_box'v'
			self:box('15%', '10%', 50, 50)
			self:label'hello'
			self:box('25%', '10%')
		self:end_content_box()
		self:box('10%', '25%')
		self:box('10%', '15%')
	self:end_content_box()
	]]

	self:setflow'h'
	self:box'20%'
	self:box'300'
	self:setflow'v'
	self:box(nil, '20%')

	self:begin_box(nil, 500, 'h', 10, 20)

		self:box(100)
		self:button{text = 'Hey', w = 100}

		self:begin_layer('layer1', 1)
			self:button{text = 'Hey 1', w = -270, h = 300}
			self:begin_layer('layer2', 2)
				self:button{text = 'Hey 2', w = -370, h = 200}
			self:end_layer()
		self:end_layer()
		self:begin_layer('layer11', 1.5)
			self:setflow'v'
			self:spacer(nil, 150)
			self:button{text = 'Hey 1.5', w = -370, h = 200}
		self:end_layer()

		self:box(100)
		self:setflow'v'
		self:box(nil, 100)
		self:button{text = 'Hey again!', h = 100}
		self:box()

	self:end_box()

	self.halign = 'r'
	self:label('hello')
	self.halign = 'c'
	self:label('hello again')
	self:label('and again')
	self.halign = 'l'
	self:label('and again')
	self:button{id='btn', text='Hi I\'m a button!', h = 26}
	self:box(nil, 100)
	self:spacer(nil, 100)
	self:box()

	self.sw = self.sw or self:stopwatch(2)
	if self:progress(self.sw) then
		self:rect(10 + self:progress(self.sw) * 100, 500, 100, 100)
	else
		self.sw = self:stopwatch(2, 'in_out_cubic')
	end

	--[[
	self.flow = 'h'
	self.halign = 'l'
	self.valign = 'c'
	self:box(300, 200)
	--self.halign = 'r'
	--self:box'200'
	self:box()
	]]
end
