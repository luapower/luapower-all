
--stdio binding (purposefully incomplete).
--Written by Cosmin Apreutesei. Public domain.

--Rationale: although the io.* library exposes FILE* handles, there's
--no API extension to work with buffers and avoid creating Lua strings.
--NOTE: files > 4 Petabytes are not supported.

local ffi = require'ffi'
local C = ffi.C
local M = {C = C}

ffi.cdef[[
typedef struct FILE FILE;

// functions we bind

int     ferror   (FILE*);
void    clearerr (FILE*);
char*   strerror (int errnum);
int     feof     (FILE*);
FILE*   freopen  (const char*, const char*, FILE*);
FILE*   fdopen   (int, const char*);
FILE*   _fdopen  (int, const char*);
int     fileno   (FILE*);
int     _fileno  (FILE*);
size_t  fread    (void*, size_t, size_t, FILE*);
size_t  fwrite   (const void*, size_t, size_t, FILE*);
int     fclose   (FILE*);

/*
// functions already bound by the standard io library

enum {
	STDIN_FILENO  = 0,
	STDOUT_FILENO = 1,
	STDERR_FILENO = 2,
	EOF           = -1,
};

enum {
	SEEK_SET = 0,
	SEEK_CUR = 1,
	SEEK_END = 2
};

typedef int64_t off64_t;

FILE*   fopen    (const char*, const char*);
FILE*   fopen64  (const char* filename, const char* mode);
FILE*   popen    (const char*, const char*);
FILE*   _popen   (const char*, const char*);
int     pclose   (FILE*);
int     _pclose  (FILE*);
FILE*   tmpfile  (void);
char*   tmpnam   (char*);
char*   tempnam  (const char*, const char*);
char*   _tempnam (const char*, const char*);
int     fflush   (FILE*);
int     remove   (const char*);
int     rename   (const char*, const char*);
int     unlink   (const char*);
int     _unlink  (const char*);
int     fseek    (FILE*, long, int);
int     fseeko64 (FILE*, off64_t, int);
off64_t ftello64 (FILE * stream);
long    ftell    (FILE*);
int     setvbuf  (FILE*, char*, int, size_t);
void    setbuf   (FILE*, char*);
*/
]]

local function str(s)
	return s ~= nil and ffi.string(s) or nil
end

M.error = C.ferror
M.clearerr = C.clearerr
M.strerror = function(errno)
	return str(C.strerror(errno))
end

local function ret(ret, ...)
	if ret then
		return ret, ...
	end
	local errno = ffi.errno()
	return nil, M.strerror(errno) or 'OS error '..errno, errno
end

function M.reopen(f0, path, mode)
	local f = C.freopen(path, mode or 'r', f0)
	return ret(f ~= nil and f == f0)
end

function M.read(f, buf, sz)
	assert(sz >= 1, 'invalid size')
	local szread = tonumber(C.fread(buf, 1, sz, f))
	return ret((szread == sz or C.feof(f) ~= 0) and szread)
end

function M.write(f, buf, sz)
	assert(sz >= 1, 'invalid size')
	local szwr = tonumber(C.fwrite(buf, 1, sz or #buf, f))
	return ret(szwr == sz)
end

local fdopen = ffi.abi'win' and C._fdopen or C.fdopen
function M.dopen(fileno, path, mode)
	local f = fdopen(fileno, mode or 'r')
	return ret(f ~= nil and ffi.gc(f, C.fclose))
end

local fileno = ffi.abi'win' and C._fileno or C.fileno
function M.fileno(f)
	local n = fileno(f)
	return ret(n ~= -1 and n)
end

--stream API

function M.reader(f)
	return function(buf, sz)
		local readsz, err = M.read(f, buf, sz)
		assert(readsz == sz, err)
	end
end

function M.writer(f)
	return function(buf, sz)
		assert(M.write(f, buf, sz))
	end
end

--hi-level API

function M.avail(f)
	local cur, err, errno = f:seek()
	if not cur then return nil, err, errno end
	local sz, err, errno = f:seek'end'
	if not sz then return nil, err, errno end
	local cur, err, errno = f:seek('set', cur)
	if not cur then return nil, err, errno end
	return sz
end

function M.readfile(file, format)
	local f, err = io.open(file, format=='t' and 'r' or 'rb')
	if not f then return nil, err, 'open' end
	local sz, err, errno = M.avail(f)
	if not sz then return nil, err, errno end
	local buf = ffi.new('uint8_t[?]', sz)
	local szread, err, errno = M.read(f, buf, sz)
	if not szread then return nil, err, errno end
	f:close()
	return buf, sz
end

function M.writefile(file, data, sz, format)
	local f = M.fopen(file, format=='t' and 'w' or 'wb')
	M.write(f, data, sz)
	f:close()
end

function M.close(file)
	return ret(C.fclose(file) == 0 and ffi.gc(file, nil) and true)
end

ffi.metatype('struct FILE', {__index = {
	reopen = M.reopen,
	close = M.close,
	fileno = M.fileno,
}})

if not ... then
	local stdio = M
	local outfd = stdio.fileno(io.stdout)
	assert(outfd == 1)
	local f = assert(stdio.dopen(outfd))
	print(f)
	f:close()
end

return M
