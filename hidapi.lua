
--hidapi ffi binding.
--Written by Cosmin Apreutesei. Public Domain.

local ffi = require'ffi'
local C = ffi.load'hidapi'
local M = {}

ffi.cdef[[
struct hid_device_;
typedef struct hid_device_ hid_device;

struct hid_device_info {
	char *path;                    // Platform-specific device path
	unsigned short vendor_id;      // Device Vendor ID
	unsigned short product_id;     // Device Product ID
	wchar_t *serial_number;        // Serial Number
	unsigned short release_number; // Device Release Number in BCD, aka Device Version Number
	wchar_t *manufacturer_string;  // Manufacturer String
	wchar_t *product_string;       // Product string
	unsigned short usage_page;     // Usage Page for this Device/Interface (Windows/Mac only).
	unsigned short usage;          // Usage for this Device/Interface (Windows/Mac only).
	// The USB interface which this logical device represents.
	// Valid on both Linux implementations in all cases, and valid on the
	// Windows implementation if the device contains more than one interface.
	int interface_number;
	struct hid_device_info *next;  // Pointer to the next device
};

int hid_init(void);
int hid_exit(void);

struct hid_device_info* hid_enumerate(unsigned short vendor_id, unsigned short product_id);
void hid_free_enumeration(struct hid_device_info *devs);

hid_device* hid_open(unsigned short vendor_id, unsigned short product_id, const wchar_t *serial_number);
void hid_close(hid_device *device);
hid_device* hid_open_path(const char *path);

int hid_write(hid_device *device, const unsigned char *data, size_t length);
int hid_read_timeout(hid_device *dev, unsigned char *data, size_t length, int milliseconds);
int hid_read(hid_device *device, unsigned char *data, size_t length);
int hid_set_nonblocking(hid_device *device, int nonblock);
int hid_send_feature_report(hid_device *device, const unsigned char *data, size_t length);
int hid_get_feature_report(hid_device *device, unsigned char *data, size_t length);

int hid_get_manufacturer_string(hid_device *device, wchar_t *string, size_t maxlen);
int hid_get_product_string(hid_device *device, wchar_t *string, size_t maxlen);
int hid_get_serial_number_string(hid_device *device, wchar_t *string, size_t maxlen);
int hid_get_indexed_string(hid_device *device, int string_index, wchar_t *string, size_t maxlen);
const wchar_t* hid_error(hid_device *device);
]]

C.hid_init()

local winapi = require'winapi'
local function mbs(ws)
	return winapi.mbs(ws)
end
local function wcs(s)
	return winapi.wcs(s)
end
local function bcd(n) return n end

function M.devices(vendor_id, product_id)
	local first_info = C.hid_enumerate(vendor_id or 0, product_id or 0)
	local devices = {}
	local info = first_info
	while info ~= nil do
		local t = {}
		t.path                = ffi.string(info.path)
		t.vendor_id           = info.vendor_id
		t.product_id          = info.product_id
		t.serial_number       = mbs(info.serial_number)
		t.release_number      = bcd(info.release_number)
		t.manufacturer_string = mbs(info.manufacturer_string)
		t.product_string      = mbs(info.product_string)
		t.usage_page          = info.usage_page
		t.usage               = info.usage
		t.interface_number    = info.interface_number
		table.insert(devices, t)
		info = info.next
	end
	if first_info ~= nil then
		C.hid_free_enumeration(first_info)
	end
	return devices
end

local dev = {}

function M.open(vendor_id, product_id, serial_number)
	local h
	if type(vendor_id) == 'string' then
		h = C.hid_open_path(vendor_id)
	else
		h = C.hid_open(vendor_id, product_id, wcs(serial_number))
	end
	if h == nil then return nil end
	local dev = {h = h, __index = dev}
	return setmetatable(dev, dev)
end

function dev:close()
	C.hid_close(self.h)
	self.h = nil
end

function dev:_check(ret)
	if ret then return ret end
	return nil, mbs(C.hid_error(self.h))
end

function dev:read(buf, sz, timeout)
	if timeout ~= nil then
		n = C.hid_read_timeout(self.h, buf, sz, timeout and timeout * 1000 or -1)
	else
		n = C.hid_read(self.h, buf, sz)
	end
	return self:_check(n ~= -1 and n)
end

function dev:block(v)
	return self:_check(C.hid_set_nonblocking(self.h, not v) == 0)
end

--self-test ------------------------------------------------------------------

if not ... then
	local dev = M.devices(4660)[1]
	pp(dev)
	local dev = M.open(dev.vendor_id, dev.product_id)
	local buf = ffi.new'uint16_t[32]'
	while true do
		local i = 0
		while i < 64 do
			local n, err = dev:read(ffi.cast('uint8_t*', buf) + i, 64 - i)
			if not n then
				error('read error')
			end
			i = i + n
		end
		for i = 0, 31 do
			print(buf[i])
		end
	end
	dev:close()
end

return M
