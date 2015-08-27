--helper functions to encode/decode the buffers for requesting info about a fbclient object
local ffi = require'ffi'
local glue = require'glue'

--end codes that can terminate an info string.
local status_codes = {
	isc_info_end       = 1, --normal ending
	isc_info_truncated = 2, --receiving buffer too small
	isc_info_error     = 3, --error, check status vector
}

local status_code_lookup = glue.index(status_codes)

local info = {}

local INT_SIZE	   = 4
local SHORT_SIZE	= 2

--recieves an array of info code names, and the catalogs of info codes and required buffer sizes,
--and returns an encoded info request string and the required info buffer length.
--note: the only info option with arguments (requiring the encoders parameter) is fb_info_page_contents.
function info.encode(info_name,opts,info_codes,info_buf_sizes,encoders)
	local s,len = '',32 --we start with a safe length
	for k,params in pairs(opts) do
		local opt_code = glue.assert(info_codes[k],'invalid %s option %s',info_name,k)
		local info_buf_size = glue.assert(info_buf_sizes[k],'invalid %s option %s (missing buffer size)',info_name,k)
		s = s..struct.pack('B',opt_code)
		if encoders and encoders[k] then
			s = s..encoders[k](params)
		else
			assert(params==true,'an option that takes no arguments must be given the value true')
		end
		len = len+1+SHORT_SIZE+info_buf_size --opt_code,buf_len,buf
    end
	return s,len
end

function info.decode_enum(enum_table)
	local enum_table_index = glue.index(enum_table) --no synonyms for enum names allowed!
	return function(s)
		return assert(enum_table_index[struct.unpack('B',s)])
	end
end

function info.decode_int(s) assert(#s == INT_SIZE); return struct.unpack('<i',s) end
function info.decode_uint(s) assert(#s == INT_SIZE); return struct.unpack('<I',s) end
function info.decode_short(s) assert(#s == SHORT_SIZE); return struct.unpack('<h',s) end
function info.decode_ushort(s) assert(#s == SHORT_SIZE); return struct.unpack('<H',s) end
function info.decode_byte(s)	assert(#s == 1); return struct.unpack('B',s) end
function info.decode_schar(s) assert(#s == 1); return struct.unpack('b',s) end

function info.decode_unsigned(s)
	if #s == 1 then
		return decode_byte(s)
	elseif #s == SHORT_SIZE then
		return decode_ushort(s)
	elseif #s == INT_SIZE then
		return decode_uint(s)
	end
	glue.assert('decode_unsigned() can\'t decode a number of %d bytes',#s)
end

function info.decode_signed(s)
	if #s == 1 then
		return decode_schar(s)
	elseif #s == SHORT_SIZE then
		return decode_short(s)
	elseif #s == INT_SIZE then
		return decode_int(s)
	end
	glue.assert('decode_signed() can\'t decode a number of %d bytes',#s)
end

function info.decode_string(s) return s end
function info.decode_boolean(s) return struct.unpack('B',s) == 1 end

--recieves a result buffer (not string!) and returns a table of the form option=body, where
--body is either decoded with a suitable decoder (if any), or undecoded, as string.
function info.decode(info_type,info_buf,info_buf_len,info_code_lookup,decoders,array_options,fbapi)
	local info={}
	local ofs=1
	pp(ffi.string(info_buf,info_buf_len))
	while true do
		--info_buf has the form: <info_cluster1>, ..., isc_info_end
		--info_cluster ::= info_code:byte, body_length:short, body:string
		--if data didn't fit in, info_buf will contain isc_info_truncated, otherwise isc_info_end.
		local info_code = info_buf[ofs]; ofs=ofs+1
		if status_code_lookup[info_code] then
			if info_code == status_codes.isc_info_end then
				break
			else
				glue.assert(false,'%s error %s',info_type,status_code_lookup[info_code])
			end
		else
			local info_name = glue.assert(info_code_lookup[info_code],'invalid %s code %d returned by server',info_type,info_code)
			local decoder = glue.assert(decoders[info_name],'%s decoder missing for option %s',info_type,info_name)
			local body_len = struct.unpack('<H',ffi.string(info_buf+ofs, 2)); ofs=ofs+SHORT_SIZE
			local body = decoder(ffi.string(info_buf + ofs, body_len),fbapi); ofs=ofs+body_len
			if array_options and array_options[info_name] then --this info_code is to be expected multiple times!
				local t = info[info_name]
				if t then
					t[#t+1] = body
				else
					t = {body}
				end
				info[info_name] = t
			else
				info[info_name] = body
			end
		end
	end
	return info
end

return info
