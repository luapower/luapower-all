local glue = require'glue'
local ffi = require'ffi'
local rsync = require'rsync'
local blake2 = require'blake2'
local stdio = require'stdio'
local pp = require'pp'
local time = require'time'

local _ = string.format

local function mb(bytes)
	return bytes / 1024^2
end

local clock0
local function mbs(bytes)
	if not bytes then
		clock0 = time.clock()
	else
		return mb(bytes) / (time.clock() - clock0)
	end
end

local function log(...)
	print(_(...))
	io.flush()
end

local function log_mbs(bytes, ...)
	log('%4dM/s: %s', mbs(bytes), _(...))
end

local function cmd_logger(block_len, verbose)
	local cmd0, block0, block1, bytes
	local total_copy = 0
	local total_data = 0
	local function print_totals()
		local total_bytes = total_data + total_copy
		log_mbs(total_bytes,
			'total: %4dM, copy: %2d%%, block_len %d',
				mb(total_bytes),
				(total_copy / total_bytes) * 100,
				block_len
		)
	end
	local last_total = 0
	local each_bytes = 1024 * 1024 * 10
	local function print_cmd0()
		if verbose then
			if cmd0 == 'copy' then
				print('>copy', block0, block1-block0 + 1)
			elseif cmd0 == 'data' then
				print('>data', bytes)
			end
		else
			if total_copy + total_data - last_total > each_bytes then
				print_totals()
				last_total = total_copy + total_data
			end
		end
	end
	mbs()
	return function(cmd, arg1, arg2)
		if cmd == 'copy' then
			total_copy = total_copy + block_len
			if cmd0 == 'copy' and block1 == arg1 - 1 then
				block1 = arg1
			else
				print_cmd0()
				cmd0 = 'copy'
				block0 = arg1
				block1 = arg1
			end
		elseif cmd then
			total_data = total_data + arg2
			if cmd0 == 'data' then
				bytes = bytes + arg2
			else
				print_cmd0()
				cmd0 = 'data'
				bytes = arg2
			end
		else --finish
			print_cmd0()
			print_totals()
		end
	end
end

local function file_reader(file)
	local f = assert(io.open(file, 'rb'))
	local stdio_reader = stdio.reader(f)
	local total_len = 0
	local function reader(buf, max_len)
		local len = stdio_reader(buf, max_len)
		total_len = total_len + len
		return len
	end
	local function get_len()
		return total_len
	end
	return reader, f, get_len
end

local function filename(file, ext)
	return file:gsub('(%.[^%.]+)$', '.'..ext..'%1')
end

local function file_writer(file)
	local f = assert(io.open(file, 'wb'))
	local stdio_writer = stdio.writer(f)
	local total_len = 0
	local function writer(buf, len)
		stdio_writer(buf, len)
		total_len = total_len + len
	end
	local function get_len()
		return total_len
	end
	return writer, f, get_len
end

ffi.cdef'int memcmp ( const void * ptr1, const void * ptr2, size_t num );'

local function diff(file1, file2)
	mbs()
	local block_len = 1024 * 64
	local block1 = ffi.new('uint8_t[?]', block_len)
	local block2 = ffi.new('uint8_t[?]', block_len)
	local f1 = io.open(file1, 'rb')
	local f2 = io.open(file2, 'rb')
	local total_len = 0
	while true do
		local len1 = assert(stdio.read(f1, block1, block_len))
		local len2 = assert(stdio.read(f2, block2, block_len))
		assert(len1 == len2)
		if len1 == 0 then break end
		assert(ffi.C.memcmp(block1, block2, len1) == 0)
		total_len = total_len + len1
	end
	f1:close()
	f2:close()
	log_mbs(total_len, 'diff ok')
end

local function test_files(file1, file2, block_len)

	local deltas_file = filename(file2, 'delta')
	local sigs_file = filename(file1, 'sig')
	local out_file = filename(file2, 'out')

	--gen sigs file from file1

	mbs()
	local read, f1, f1_len = file_reader(file1)
	local write, fsig, fsig_len = file_writer(sigs_file)
	local sig_count = rsync:gen_sigs_file(read, write, block_len)
	f1:close()
	fsig:close()
	log_mbs(f1_len(), 'gen_sigs_file:  %d sigs = %5.1fMB', sig_count,
		mb(fsig_len()))

	--load sigs file into hash maps

	mbs()
	local read, fsig, fsig_len = file_reader(sigs_file)
	local sigs = rsync:load_sigs_file(read)
	assert(sigs.count == sig_count)
	log_mbs(fsig_len(), 'load_sigs_file: %d sigs = %5.1fMB', sig_count,
		mb(fsig_len()))
	fsig:close()

	--gen deltas file from sigs file + file2

	mbs()
	local read, f2, f2_len = file_reader(file2)
	local log_cmd = cmd_logger(block_len)
	local write, fd, fd_len = file_writer(deltas_file)
	local write_cmd_tofile = rsync:cmd_writer(write)
	local function write_cmd(cmd, arg1, arg2)
		log_cmd(cmd, arg1, arg2)
		write_cmd_tofile(cmd, arg1, arg2)
	end
	local false_alarms, good_alarms =
		rsync:gen_deltas(read, sigs, write_cmd, block_len)
	log_cmd()
	f2:close()
	fd:close()
	log_mbs(fd_len(), 'gen_deltas_file: %5.1fM, false alarms: %5.2f%%',
		mb(fd_len()),
		false_alarms / good_alarms * 100)

	--patch file1 from deltas file + file1 into the output file

	mbs()
	local _, f1 = file_reader(file1)
	local function seek(offset)
		assert(f1:seek('set', offset))
	end
	local read = stdio.reader(f1)
	local read_fd, fd = file_reader(deltas_file)
	local read_cmd = rsync:cmd_reader(read_fd)
	local write_fout, fout, out_len = file_writer(out_file)
	rsync:patch(read_cmd, seek, read, write_fout, block_len)
	f1:close()
	fd:close()
	fout:close()
	log_mbs(out_len(), 'patched %dM to %s', mb(out_len()), out_file)

	--diff file2 with output file

	diff(file2, out_file)

end

local function test_copy(file1, block_len)
	mbs()
	local block = ffi.new('uint8_t[?]', block_len)
	local f1 = io.open(file1, 'rb')
	local file2 = filename(file1, 'copy')
	local f2 = io.open(file2, 'wb')
	local total_len = 0
	local total_blocks = 0
	while true do
		local len = assert(stdio.read(f1, block, block_len))
		if len == 0 then break end
		assert(stdio.write(f2, block, len))
		total_len = total_len + len
		total_blocks = total_blocks + 1
	end
	f1:close()
	f2:close()
	log_mbs(total_len, 'plain copy: %5dM, %5d blocks of %d bytes each',
		mb(total_len),
		total_blocks,
		block_len)
end

test_copy('media/rsync/linux-master.tar', 1024 * 64)

test_files(
	'media/rsync/linux-master.tar',
	'media/rsync/linux-master.tar',
	691
)

test_files(
	--'media/rsync/linux-4.10-rc2.tar',
	'media/rsync/linux-4.14-rc7.tar',
	--'media/rsync/linux-master.tar',
	'media/rsync/linux-master.tar',
	1024
	--691
)

test_files(
	'media/rsync/freetype2-VER-2-5-0.tar',
	'media/rsync/freetype2-master.tar',
	877
)

test_files(
	'media/rsync/cairo-1.15.2.tar',
	'media/rsync/cairo-master.tar',
	1117
)

