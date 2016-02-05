--template-based encoder frunction for PBs (Parameter Blocks, i.e. TPB, DPB, etc.)
--pb.encode(options_t, codes, encoders) -> encoded_options_string
--pb.encode_*(v) -> encoded option string

local asserts = require'glue'.assert
local struct = require'struct'
local pb = {}

-- encode_*() functions used for encoding individual PB options in encoders table passed to encode().

local INT_SIZE    = 4
local SHORT_SIZE  = 2
local LONG_SIZE   = 4
local POINTER_SIZE= 4
local MIN_INT     = -2^(8*INT_SIZE-1)
local MAX_INT     =  2^(8*INT_SIZE-1)-1
local MAX_UINT	   =  2^(8*INT_SIZE)-1
local MIN_SHORT   = -2^(8*SHORT_SIZE-1)
local MAX_SHORT   =  2^(8*SHORT_SIZE-1)-1
local MAX_USHORT  =  2^(8*SHORT_SIZE)-1
local MAX_BYTE    =  2^8-1
local MIN_SCHAR   = -2^7
local MAX_SCHAR   =  2^7-1

local function isint(v) return v%1 == 0 and v >= MIN_INT and v <= MAX_INT end
local function isuint(v) return v%1 == 0 and v >= 0 and v <= MAX_UINT end
local function isshort(v) return v%1 == 0 and v >= MIN_SHORT and v <= MAX_SHORT end
local function isushort(v) return v%1 == 0 and v >= 0 and v <= MAX_USHORT end
local function isbyte(v) return v%1 == 0 and v >= 0 and v <= MAX_BYTE end
local function isschar(v) return v%1 == 0 and v >= MIN_SCHAR and v <= MAX_SCHAR end

function pb.encode_enum(t)
	return function(v)
		local tv = asserts(t[v],'invalid enum constant %s',v)
		assert(isbyte(tv))
		return struct.pack('BB',1,tv)
	end
end

function pb.encode_int(v)
	assert(isint(v),'32bit signed integer expected')
	return struct.pack('<Bi',INT_SIZE,v)
end

function pb.encode_uint(v)
	assert(isuint(v),'32bit unsigned integer expected')
	return struct.pack('<BI',INT_SIZE,v)
end

function pb.encode_short(v,opt)
	assert(isshort(v),'16bit signed integer expected')
	return struct.pack('<Bh',SHORT_SIZE,v)
end

function pb.encode_ushort(v)
	assert(isushort(v),'16bit unsigned integer expected')
	return struct.pack('<BH',SHORT_SIZE,v)
end

function pb.encode_byte(v)
	assert(isbyte(v),'8bit unsigned integer expected')
	return struct.pack('BB',1,v)
end

function pb.encode_schar(v)
	assert(isschar(v),'8bit signed integer expected')
	return struct.pack('BB',1,v)
end

function pb.encode_bool(v)
	return struct.pack('BB',1,v and 1 or 0)
end

function pb.encode_string(v)
	asserts(#v <= MAX_BYTE,'strint too long, max. is %d bytes',MAX_BYTE)
	return struct.pack('Bc0',#v,v)
end

-- this is the encoder for options that can take no arguments as described for DPBs
function pb.encode_zero(v)
	assert(v==true,'an option that takes no arguments must be given the value true')
	return struct.pack('BB',1,0)
end

-- this is the encoder for options that can take no arguments as described for TPBs
function pb.encode_none(v)
	assert(v==true,'an option that takes no arguments must be given the value true')
	return ''
end

-- isc_dpb_shutdown is the only user of this encoder
function pb.encode_bitmask(bits)
	return function(v)
		local n = 0
		for k,v in pairs(t) do
			local bit = asserts(bits[k],'invalid bitmask option %s',k)
			assert(v==true,'an option that takes no arguments must be given the value true')
			-- adding the bitmasks does not carry so it's equivalent to binary and in this case
			n = n + bit
		end
		assert(isbyte(n))
		return struct.pack('B',n)
	end
end

--recieves an optional table of options and option arguments, and a table of encoders; returns a PB.
--options can have arguments, which will be handled by an encoder from the encoders table.
function pb.encode(pb_type, pb_header, opts, codes, encoders)
	local s = pb_header
	if opts then
		for k,v in pairs(opts) do
			if type(k) == 'string' then --we can have options in the array part (see tpb.lua) that we ignore here!
				asserts(codes[k] and encoders[k],'invalid %s: invalid option %s', pb_type, k)
				local ok,v = pcall(encoders[k],v)
				asserts(ok,'invalid %s: invalid option %s: %s',pb_type,k,v)
				s = s..struct.pack('B',codes[k])..v
			end
		end
	end
	return s
end

return pb

