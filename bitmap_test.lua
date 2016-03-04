--go@ luajit -e io.stdout:setvbuf'no' *
local bitmap = require'bitmap'
local glue = require'glue'
require'unit'
io.stdout:setvbuf'no'

bitmap.dumpinfo()
print()

for src_format in glue.sortedpairs(bitmap.formats) do

	print(string.format('%-6s %-4s %-10s %-10s %9s %9s %7s %13s',
			'time', '', 'src', 'dst', 'src size', 'dst size', 'stride', 'r+w speed'))

	jit.flush()
	for dst_format in bitmap.conversions(src_format) do
		local src = bitmap.new(1921, 1081, src_format)
		local dst = bitmap.new(1921, 1081, dst_format, 'flipped', 'aligned')

		timediff()
		bitmap.paint(src, dst)
		local dt = timediff()

		local flag = src_format == dst_format and '*' or ''
		print(string.format('%-6.4f %-4s %-10s %-10s %6.2f MB %6.2f MB   %-7s %6d MB/s',
				dt, flag, src.format, dst.format, src.size / 1024^2, dst.size / 1024^2, src.stride,
				(src.size + dst.size) / 1024^2 / dt))
	end

end

