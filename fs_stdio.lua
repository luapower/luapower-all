
--stdio: opening / closing ---------------------------------------------------

cdef[[
typedef struct FILE FILE;
int fclose (FILE*);
]]

local FILE = ffi.typeof'struct FILE*'

--convert an io.open()'ed file to a fs file so we can use fs methods on it
function fs.file(f)
	return ffi.cast(FILE, f)
end

function fs.isfile(f)
	return ffi.istype(FILE, f)
end

local fopen

if win then

	cdef[[
	FILE* _wfopen(const wchar_t *filename, const wchar_t *mode);
	FILE* _fdopen (int fd, const char *mode);
	int _fileno (struct FILE *stream);
	intptr_t _get_osfhandle(int fd);
	]]

	function fopen(path, mode)
		return C._wfopen(wcs(path), wcs(mode, nil, wbuf))
	end

else

	cdef[[
	FILE* fopen (const char *filename, const char *mode);
	FILE* fdopen (int fd, const char *mode);
	int fileno (struct FILE *stream);
	]]

	fopen = C.fopen

end

local function open_filename(path, mode)
	local f = fopen(path, mode or 'r')
	return check_errno(f ~= nil and f)
end

local fdopen = win and C._fdopen or C.fdopen
local function open_fd(fd, mode)
	local f = fdopen(fd, mode)
	return check_errno(f ~= nil and f)
end

local function tie(f, ...)
	if not f then return nil, ... end
	ffi.gc(f, fs.close)
	return f
end
function fs.open(file, ...)
	if type(file) == 'string' then --filename
		return tie(open_filename(file, ...))
	elseif type(file) == 'number' then --fd
		return tie(open_fd(file, ...))
	end
end

function fs.close(f)
	local ret = C.fclose(f)
	if ret ~= 0 then return check() end
	ffi.gc(f, nil)
	return true
end
file.close = fs.close

local fileno = win and C._fileno or C.fileno
function fs.fileno(f)
	local fd = fileno(f)
	return check(fd ~= -1 and fd)
end
file.fileno = fs.fileno

if win then

	function fs.handle(f)
		local fileno, err, errcode = fs.fileno(f)
		if not fileno then return nil, err, errcode end
		local h = C._get_osfhandle(fileno)
		if h == INVALID_HANDLE_VALUE then
			return nil, 'Invalid file descriptor'
		end
		return h
	end

else

	function fs.handle(f)
		return nil, 'N/A'
	end

end
file.handle = fs.handle

--seeking --------------------------------------------------------------------

cdef'int feof(FILE*);'
function fs.eof(f)
	return C.feof(f) ~= 0
end
file.eof = fs.eof

local whences = {set = 0, cur = 1, ['end'] = 2}

if win then
	--_lseeki64( _fileno( stream ), offset, whence ); }
	--_telli64( _fileno( stream )); }

else

	local fseek = win and 'fseeko64' or osx and 'fseeko' or 'fseeko64'
	cdef('int %s(FILE *stream, int64_t offset, int origin);', fseek)
	fseek = C[fseek]

	local ftell = win and 'ftello64' or osx and 'ftello' or 'ftello64'
	cdef('int64_t %s(FILE *stream);', ftell)
	ftell = C[ftell]

end

function fs.seek(f, whence, offset)
	whence = assert(whences[whence or 'cur'], 'invalid whence')
	local ret = fseek(f, offset or 0, whence)
	if ret ~= 0 then return check_errno() end
	return check_errno(ftell(f) == 0)
end

--i/o ------------------------------------------------------------------------

cdef[[
size_t fread  (void*, size_t, size_t, FILE*);
size_t fwrite (const void*, size_t, size_t, FILE*);
]]

function nullread(f, len)
	local cur0, err, errno = f:seek()
	if not cur0 then return nil, err, errno end
	local cur, err, errno = f:seek('cur', len)
	if not cur then return nil, err, errno end
	return cur - cur0
end

function fs.read(f, buf, len)
	if len == 0 then return 0 end
	assert(len >= 1, 'invalid size')
	if not buf then
		return nullread(f, len)
	else
		local readlen = tonumber(C.fread(buf, 1, len, f))
		return ret((readlen == len or f:eof()) and readlen)
	end
end
file.read = fs.read

function fs.write(f, buf, len)
	len = len or #buf
	if len == 0 then return true end
	assert(len >= 1, 'invalid size')
	local wlen = tonumber(C.fwrite(buf, 1, len, f))
	return ret(wlen == len)
end
file.write = fs.write

--text/binary mode -----------------------------------------------------------


local settextmode

if win then

	cdef[[
	int _setmode(int fd, int mode);
	]]

	function set_textmode(f, mode)
		local mode = mode == 't' and 0x4000 or 0x8000
		return check(C._setmode(f:fileno(), mode) ~= -1)
	end

else

	function set_textmode(f, mode)
		return true, 'binary'
	end

end

function fs.textmode(f, mode)
	local mode = assert(mode:match'^[bt]', 'invalid mode')
	return settextmode(f, mode)
end
file.textmode = fs.texmode


cdef[[
int _setmode(int fd, int mode);
]]

function fs.set_textmode(f, mode)
	local mode = mode == 't' and 0x4000 or 0x8000
	return check(C._setmode(f:fileno(), mode) ~= -1)
end
file.set_textmode = fs.set_textmode

ffi.metatype('struct FILE', {__index = file})

