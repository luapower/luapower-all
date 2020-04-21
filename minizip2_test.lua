
local zip = require'minizip2'
local ffi = require'ffi'
local fs = require'fs'
local glue = require'glue'

--TODO: test certificate-based signing.

local function dump(z)
	print('dir', 'comp', 'mtime', 'atime', 'btime', 'crc',
		'usize', 'csize', 'disknum', 'diskoff', 'ifa', 'efa', 'zip64', 'zipcd',
		'aesver', 'aesbits', 'md5', 'sha1', 'sha256',
		'byte1', 'sign', 'verif', 'filename', 'comm', 'link')
	for e in z:entries() do
		local zip_cd = z.zip_cd
		assert(z:open_entry())
		local has_sign = not z.entry_is_dir and z.file_has_sign
		local verify_sign = not z.entry_is_dir and z:file_verify_sign()
		local buf = ffi.new'char[1]'
		z:read(buf, 1)
		z:close_entry() --TODO: gives crc error, why??
		print(
			z.entry_is_dir,
			e.compression_method,
			os.date('!%H:%M', e.mtime),
			os.date('!%H:%M', e.atime),
			os.date('!%H:%M', e.btime),
			tostring(e.crc):sub(1, 7),
			e.compressed_size,
			e.uncompressed_size,
			e.disk_number,
			e.disk_offset,
			e.internal_fa,
			e.external_fa,
			e.zip64,
			zip_cd,
			e.aes_version,
			e.aes_bits,
			glue.tohex(z:entry_hash'md5' or ''):sub(1, 7),
			glue.tohex(z:entry_hash'sha1' or ''):sub(1, 7),
			glue.tohex(z:entry_hash'sha256' or ''):sub(1, 7),
			glue.tohex(string.char(buf[0])),
			has_sign,
			verify_sign,
			e.filename,
			e.comment,
			e.linkname
		)
		local s, err = z:read'*a' --opens entry automatically
		if z.entry_is_dir then
			assert(s == nil, err)
			assert(err == nil, err)
		else
			assert(s:find'^hello', s)
		end
	end
end

local z = assert(zip.open{
	file = 'media/zip/test-aes.zip',
	password = '123',
	--sign_required = true, --TODO: test signing
})
dump(z)
assert(z:find'test/a/x/test1.txt')
assert(z.entry_is_dir == false)

z:open_entry()
assert(z.file_has_sign == false)
assert(z:file_verify_sign() == false)

assert(z:find'test/a/')
assert(z.entry_is_dir == true)
z:open_entry()
--directories cannot have signature
assert(pcall(function() return z:entry_has_sign() end) == false)

assert(z:extract_all'tmp/minizip-test')

z:close()

local z = zip.open{
	file = 'media/zip/test-aes2.zip',
	mode = 'w',
	password = '321',
	--Total Commander cannot see this!
	--Windows Explorer on Windows 10 cannot see this!
	--zip_cd = true,
}
--Windows Explorer on Windows 10 cannot decrypt this!
z.aes = false
z:add_all('tmp/minizip-test')
z:close()

assert(fs.remove('tmp/minizip-test', true))

local z = zip.open('media/zip/test-aes2.zip', 'r', '321')

dump(z)

z:extract_all'tmp/minizip-test'

z:close()

assert(fs.remove('tmp/minizip-test', true))

print'done'
