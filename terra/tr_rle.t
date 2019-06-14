
--Abstract run-length-encoding iterator for any indexable object.

setfenv(1, require'terra/low')

--NOTE: this could probably be achieved with a simple for loop and even less
--conditionals in the loop if you are willing to have some code generated twice.
--It might be worth making a no-goto version and compare it for speed. Make
--sure to handle 0, 1 and n-length sequences correctly as this version does.

function rle_iterator(iter)
	local struct rle_iter { state: iter.state; i: int; j: int }
	function rle_iter.metamethods.__for(self, body)
		local save_values = label()
		local advance     = label()
		local load_values = label()
		local iterate     = label()
		local continue    = label()
		local done        = label()
		return quote
				var i = self.i
				var j = self.j
				if i >= j then goto [done] end
				var i0: int
				[ iter.declare_variables(`self.state) ]
				var first_time = true
				goto [load_values]
			::[save_values]::
				[ iter.save_values(`self.state) ]
				i0 = i
			::[advance]::
				i = i + 1
				if i == j then goto [iterate] end
			::[load_values]::
				[ iter.load_values(`self.state, i) ]
				if first_time then first_time = false; goto [save_values] end
				if not [ iter.values_different(`self.state, i) ] then goto [advance] end
			::[iterate]::
				while true do --this loop is only to allow `break` to be used in body
					[ body(i0, `i - i0, unpack(iter.for_variables)) ]
					goto [continue]
				end
				goto [done] --break in body
			::[continue]::
				if i == j then goto [done] end
				goto [save_values]
			::[done]::
		end
	end
	return rle_iter
end

if not ... then --self-test

	local iter = {}
	iter.state = arr(int)
	local v0 = symbol(int, 'v0')
	local v1 = symbol(int, 'v1')
	iter.for_variables = {v0}
	function iter.declare_variables()
		return quote
			var [v0], [v1]
		end
	end
	function iter.save_values()
		return quote
			v0 = v1
		end
	end
	function iter.load_values(self, i)
		return quote
			v1 = self(i)
		end
	end
	function iter.values_different()
		return `v1 ~= v0
	end
	local iter = rle_iterator(iter)

	terra test()
		var a = arr(int)
		a:add(5)
		a:add(5)
		a:add(7)
		a:add(7)
		a:add(8)
		for i, len, v in iter {a, 0, a.len} do
			print(i, len, v)
		end
	end
	test()

end
