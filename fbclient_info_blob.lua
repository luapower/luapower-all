--encode the request buffer and decode the reply buffer for requesting information about a blob.

local info = require'fbclient_info'
local glue = require'glue'
local INT_SIZE	   = 4

local info_codes = {
	isc_info_blob_num_segments	= 4, --total number of segments
	isc_info_blob_max_segment	= 5, --length of the longest segment
	isc_info_blob_total_length	= 6, --total size, in bytes, of blob
	isc_info_blob_type			= 7, --type of blob (0: segmented, or 1: stream)
}

local info_code_lookup = glue.index(info_codes)

local info_buf_sizes = {
	isc_info_blob_num_segments	= INT_SIZE,	-- could not test (returns data_not_ready)
	isc_info_blob_max_segment	= INT_SIZE,
	isc_info_blob_total_length	= INT_SIZE,
	isc_info_blob_type			= 1,
}

local isc_bpb_type_enum = {
	isc_bpb_type_segmented = 0,
	isc_bpb_type_stream = 1,
}

local decoders = {
	isc_info_blob_num_segments	= info.decode_unsigned,
	isc_info_blob_max_segment	= info.decode_unsigned,
	isc_info_blob_total_length	= info.decode_unsigned,
	isc_info_blob_type			= info.decode_enum(isc_bpb_type_enum),
}

local blobinfo = {}

function blobinfo.encode(opts)
	return info.encode('BLOB_INFO', opts, info_codes, info_buf_sizes)
end

function blobinfo.decode(info_buf, info_buf_len)
	return info.decode('BLOB_INFO', info_buf, info_buf_len, info_code_lookup, decoders)
end

return blobinfo
