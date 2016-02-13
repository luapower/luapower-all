--result of cpp stdio.h from mingw
local ffi = require'ffi'
require'ctypes'

ffi.cdef[[
typedef struct FILE_ FILE;
typedef long long fpos_t;

enum {
	STDIN_FILENO   = 0,
	STDOUT_FILENO  = 1,
	STDERR_FILENO  = 2,
	EOF            = -1,
	SEEK_SET       = 0,
	SEEK_CUR       = 1,
	SEEK_END       = 2
};

FILE* fopen (const char*, const char*);
FILE* freopen (const char*, const char*, FILE*);
int fflush (FILE*);
int fclose (FILE*);
int remove (const char*);
int rename (const char*, const char*);
FILE* tmpfile (void);
char* tmpnam (char*);
char* _tempnam (const char*, const char*);
int _rmtmp(void);
int _unlink (const char*);
char* tempnam (const char*, const char*);
int rmtmp(void);
int unlink (const char*);
int setvbuf (FILE*, char*, int, size_t);
void setbuf (FILE*, char*);
int fprintf (FILE*, const char*, ...);
int printf (const char*, ...);
int sprintf (char*, const char*, ...);
int vfprintf (FILE*, const char*, __gnuc_va_list);
int vprintf (const char*, __gnuc_va_list);
int vsprintf (char*, const char*, __gnuc_va_list);
int _snprintf (char*, size_t, const char*, ...);
int _vsnprintf (char*, size_t, const char*, __gnuc_va_list);
int _vscprintf (const char*, __gnuc_va_list);
int snprintf (char *, size_t, const char *, ...);
int vsnprintf (char *, size_t, const char *, __gnuc_va_list);
int vscanf (const char * __restrict__, __gnuc_va_list);
int vfscanf (FILE * __restrict__, const char * __restrict__, __gnuc_va_list);
int vsscanf (const char * __restrict__, const char * __restrict__, __gnuc_va_list);
int fscanf (FILE*, const char*, ...);
int scanf (const char*, ...);
int sscanf (const char*, const char*, ...);
int fgetc (FILE*);
char* fgets (char*, int, FILE*);
int fputc (int, FILE*);
int fputs (const char*, FILE*);
char* gets (char*);
int puts (const char*);
int ungetc (int, FILE*);
int _filbuf (FILE*);
int _flsbuf (int, FILE*);
int getc (FILE* __F);
int putc (int __c, FILE* __F);
int getchar (void);
int putchar(int __c);
size_t fread (void*, size_t, size_t, FILE*);
size_t fwrite (const void*, size_t, size_t, FILE*);
int fseek (FILE*, long, int);
long ftell (FILE*);
void rewind (FILE*);
int fgetpos (FILE*, fpos_t*);
int fsetpos (FILE*, const fpos_t*);
int feof (FILE*);
int ferror (FILE*);
void clearerr (FILE*);
void perror (const char*);
FILE* _popen (const char*, const char*);
int _pclose (FILE*);
FILE* popen (const char*, const char*);
int pclose (FILE*);
int _flushall (void);
int _fgetchar (void);
int _fputchar (int);
FILE* _fdopen (int, const char*);
int _fileno (FILE*);
int _fcloseall (void);
FILE* _fsopen (const char*, const char*, int);
int _getmaxstdio (void);
int _setmaxstdio (int);
int fgetchar (void);
int fputchar (int);
FILE* fdopen (int, const char*);
int fileno (FILE*);
FILE* fopen64 (const char* filename, const char* mode);
int fseeko64 (FILE*, off64_t, int);
off64_t ftello64 (FILE * stream);
int fwprintf (FILE*, const wchar_t*, ...);
int wprintf (const wchar_t*, ...);
int _snwprintf (wchar_t*, size_t, const wchar_t*, ...);
int vfwprintf (FILE*, const wchar_t*, __gnuc_va_list);
int vwprintf (const wchar_t*, __gnuc_va_list);
int _vsnwprintf (wchar_t*, size_t, const wchar_t*, __gnuc_va_list);
int _vscwprintf (const wchar_t*, __gnuc_va_list);
int fwscanf (FILE*, const wchar_t*, ...);
int wscanf (const wchar_t*, ...);
int swscanf (const wchar_t*, const wchar_t*, ...);
wint_t fgetwc (FILE*);
wint_t fputwc (wchar_t, FILE*);
wint_t ungetwc (wchar_t, FILE*);
int swprintf (wchar_t*, const wchar_t*, ...);
int vswprintf (wchar_t*, const wchar_t*, __gnuc_va_list);
wchar_t* fgetws (wchar_t*, int, FILE*);
int fputws (const wchar_t*, FILE*);
wint_t getwc (FILE*);
wint_t getwchar (void);
wchar_t* _getws (wchar_t*);
wint_t putwc (wint_t, FILE*);
int _putws (const wchar_t*);
wint_t putwchar (wint_t);
FILE* _wfdopen(int, const wchar_t *);
FILE* _wfopen (const wchar_t*, const wchar_t*);
FILE* _wfreopen (const wchar_t*, const wchar_t*, FILE*);
FILE* _wfsopen (const wchar_t*, const wchar_t*, int);
wchar_t* _wtmpnam (wchar_t*);
wchar_t* _wtempnam (const wchar_t*, const wchar_t*);
int _wrename (const wchar_t*, const wchar_t*);
int _wremove (const wchar_t*);
void _wperror (const wchar_t*);
FILE* _wpopen (const wchar_t*, const wchar_t*);
int snwprintf (wchar_t* s, size_t n, const wchar_t* format, ...);
int vsnwprintf (wchar_t* s, size_t n, const wchar_t* format, __gnuc_va_list arg);
int vwscanf (const wchar_t * __restrict__, __gnuc_va_list);
int vfwscanf (FILE * __restrict__, const wchar_t * __restrict__, __gnuc_va_list);
int vswscanf (const wchar_t * __restrict__, const wchar_t * __restrict__, __gnuc_va_list);
FILE* wpopen (const wchar_t*, const wchar_t*);
wint_t _fgetwchar (void);
wint_t _fputwchar (wint_t);
int _getw (FILE*);
int _putw (int, FILE*);
wint_t fgetwchar (void);
wint_t fputwchar (wint_t);
int getw (FILE*);
int putw (int, FILE*);
]]
