--mz.h & mz_zip.h 2.9.1 Zip manipulation
local ffi = require'ffi'
ffi.cdef[[
enum {
	MZ_OK                           =  0,
	MZ_STREAM_ERROR                 = -1,
	MZ_DATA_ERROR                   = -3,
	MZ_MEM_ERROR                    = -4,
	MZ_BUF_ERROR                    = -5,
	MZ_VERSION_ERROR                = -6,

	MZ_END_OF_LIST                  = -100,
	MZ_END_OF_STREAM                = -101,

	MZ_PARAM_ERROR                  = -102,
	MZ_FORMAT_ERROR                 = -103,
	MZ_INTERNAL_ERROR               = -104,
	MZ_CRC_ERROR                    = -105,
	MZ_CRYPT_ERROR                  = -106,
	MZ_EXIST_ERROR                  = -107,
	MZ_PASSWORD_ERROR               = -108,
	MZ_SUPPORT_ERROR                = -109,
	MZ_HASH_ERROR                   = -110,
	MZ_OPEN_ERROR                   = -111,
	MZ_CLOSE_ERROR                  = -112,
	MZ_SEEK_ERROR                   = -113,
	MZ_TELL_ERROR                   = -114,
	MZ_READ_ERROR                   = -115,
	MZ_WRITE_ERROR                  = -116,
	MZ_SIGN_ERROR                   = -117,
	MZ_SYMLINK_ERROR                = -118,

	MZ_OPEN_MODE_READ               = 0x01,
	MZ_OPEN_MODE_WRITE              = 0x02,
	MZ_OPEN_MODE_READWRITE          = MZ_OPEN_MODE_READ | MZ_OPEN_MODE_WRITE,
	MZ_OPEN_MODE_APPEND             = 0x04,
	MZ_OPEN_MODE_CREATE             = 0x08,
	MZ_OPEN_MODE_EXISTING           = 0x10,

	MZ_SEEK_SET                     = 0,
	MZ_SEEK_CUR                     = 1,
	MZ_SEEK_END                     = 2,

	MZ_COMPRESS_METHOD_STORE        = 0,
	MZ_COMPRESS_METHOD_DEFLATE      = 8,
	MZ_COMPRESS_METHOD_BZIP2        = 12,
	MZ_COMPRESS_METHOD_LZMA         = 14,
	MZ_COMPRESS_METHOD_AES          = 99,

	MZ_COMPRESS_LEVEL_DEFAULT       = -1,
	MZ_COMPRESS_LEVEL_FAST          = 2,
	MZ_COMPRESS_LEVEL_NORMAL        = 6,
	MZ_COMPRESS_LEVEL_BEST          = 9,

	MZ_ZIP_FLAG_ENCRYPTED           = 1 << 0,
	MZ_ZIP_FLAG_LZMA_EOS_MARKER     = 1 << 1,
	MZ_ZIP_FLAG_DEFLATE_MAX         = 1 << 1,
	MZ_ZIP_FLAG_DEFLATE_NORMAL      = 0,
	MZ_ZIP_FLAG_DEFLATE_FAST        = 1 << 2,
	MZ_ZIP_FLAG_DEFLATE_SUPER_FAST  = MZ_ZIP_FLAG_DEFLATE_FAST | MZ_ZIP_FLAG_DEFLATE_MAX,
	MZ_ZIP_FLAG_DATA_DESCRIPTOR     = 1 << 3,
	MZ_ZIP_FLAG_UTF8                = 1 << 11,
	MZ_ZIP_FLAG_MASK_LOCAL_INFO     = 1 << 13,

	MZ_ZIP_EXTENSION_ZIP64          = 0x0001,
	MZ_ZIP_EXTENSION_NTFS           = 0x000a,
	MZ_ZIP_EXTENSION_AES            = 0x9901,
	MZ_ZIP_EXTENSION_UNIX1          = 0x000d,
	MZ_ZIP_EXTENSION_SIGN           = 0x10c5,
	MZ_ZIP_EXTENSION_HASH           = 0x1a51,
	MZ_ZIP_EXTENSION_CDCD           = 0xcdcd,

	MZ_ZIP64_AUTO                   = 0,
	MZ_ZIP64_FORCE                  = 1,
	MZ_ZIP64_DISABLE                = 2,

	MZ_HOST_SYSTEM_MSDOS            = 0,
	MZ_HOST_SYSTEM_UNIX             = 3,
	MZ_HOST_SYSTEM_WINDOWS_NTFS     = 10,
	MZ_HOST_SYSTEM_RISCOS           = 13,
	MZ_HOST_SYSTEM_OSX_DARWIN       = 19,

	MZ_PKCRYPT_HEADER_SIZE          = 12,

	MZ_AES_VERSION                  = 1,
	MZ_AES_ENCRYPTION_MODE_128      = 0x01,
	MZ_AES_ENCRYPTION_MODE_192      = 0x02,
	MZ_AES_ENCRYPTION_MODE_256      = 0x03,
	MZ_AES_KEY_LENGTH_MAX           = 32,
	MZ_AES_BLOCK_SIZE               = 16,
	MZ_AES_FOOTER_SIZE              = 10,

	MZ_HASH_MD5                     = 10,
	MZ_HASH_MD5_SIZE                = 16,
	MZ_HASH_SHA1                    = 20,
	MZ_HASH_SHA1_SIZE               = 20,
	MZ_HASH_SHA256                  = 23,
	MZ_HASH_SHA256_SIZE             = 32,
	MZ_HASH_MAX_SIZE                = 256,

	MZ_ENCODING_CODEPAGE_437        = 437,
	MZ_ENCODING_CODEPAGE_932        = 932,
	MZ_ENCODING_CODEPAGE_936        = 936,
	MZ_ENCODING_CODEPAGE_950        = 950,
	MZ_ENCODING_UTF8                = 65001,
};

typedef size_t time_t;

/***************************************************************************/

typedef struct mz_zip_file_s
{
	uint16_t version_madeby;            /* version made by */
	uint16_t version_needed;            /* version needed to extract */
	uint16_t flag;                      /* general purpose bit flag */
	uint16_t compression_method_num;    /* compression method */
	time_t   mtime_t;                   /* last modified date in unix time */
	time_t   atime_t;                   /* last accessed date in unix time */
	time_t   btime_t;                   /* creation date in unix time */
	uint32_t crc;                       /* crc-32 */
	int64_t  compressed_size_i64;       /* compressed size */
	int64_t  uncompressed_size_i64;     /* uncompressed size */
	uint16_t filename_size;             /* filename length */
	uint16_t extrafield_size;           /* extra field length */
	uint16_t comment_size;              /* file comment length */
	uint32_t disk_number;               /* disk number start */
	int64_t  disk_offset_i64;           /* relative offset of local header */
	uint16_t internal_fa;               /* internal file attributes */
	uint32_t external_fa;               /* external file attributes */

	const char     *filename_ptr;       /* filename utf8 null-terminated string */
	const uint8_t  *extrafield_ptr;     /* extrafield data */
	const char     *comment_ptr;        /* comment utf8 null-terminated string */
	const char     *linkname_ptr;       /* sym-link filename utf8 null-terminated string */

	uint16_t zip64_u16;                 /* zip64 extension mode */
	uint16_t aes_version;               /* winzip aes extension if not 0 */
	uint8_t  aes_encryption_mode;       /* winzip aes encryption mode */

} mz_zip_file, mz_zip_entry;

/***************************************************************************/

typedef int32_t (*mz_zip_locate_entry_cb)(void *handle, void *userdata, mz_zip_file *file_info);

/***************************************************************************/

void *  mz_zip_create(void **handle);
void    mz_zip_delete(void **handle);
int32_t mz_zip_open(void *handle, void *stream, int32_t mode);
int32_t mz_zip_close(void *handle);
int32_t mz_zip_get_comment(void *handle, const char **comment);
int32_t mz_zip_set_comment(void *handle, const char *comment);
int32_t mz_zip_get_version_madeby(void *handle, uint16_t *version_madeby);
int32_t mz_zip_set_version_madeby(void *handle, uint16_t version_madeby);
int32_t mz_zip_set_recover(void *handle, uint8_t recover);
int32_t mz_zip_get_stream(void *handle, void **stream);
int32_t mz_zip_set_cd_stream(void *handle, int64_t cd_start_pos, void *cd_stream);
int32_t mz_zip_get_cd_mem_stream(void *handle, void **cd_mem_stream);

/***************************************************************************/

int32_t mz_zip_entry_is_open(void *handle);
int32_t mz_zip_entry_read_open(void *handle, uint8_t raw, const char *password);
int32_t mz_zip_entry_read(void *handle, void *buf, int32_t len);
int32_t mz_zip_entry_read_close(void *handle, uint32_t *crc32, int64_t *compressed_size, int64_t *uncompressed_size);
int32_t mz_zip_entry_write_open(void *handle, const mz_zip_file *file_info, int16_t compress_level, uint8_t raw, const char *password);
int32_t mz_zip_entry_write(void *handle, const void *buf, int32_t len);
int32_t mz_zip_entry_write_close(void *handle, uint32_t crc32, int64_t compressed_size, int64_t uncompressed_size);
int32_t mz_zip_entry_is_dir(void *handle);
int32_t mz_zip_entry_is_symlink(void *handle);
int32_t mz_zip_entry_get_info(void *handle, mz_zip_file **file_info);
int32_t mz_zip_entry_get_local_info(void *handle, mz_zip_file **local_file_info);
int32_t mz_zip_entry_set_extrafield(void *handle, const uint8_t *extrafield, uint16_t extrafield_size);
int32_t mz_zip_entry_close_raw(void *handle, int64_t uncompressed_size, uint32_t crc32);
int32_t mz_zip_entry_close(void *handle);

/***************************************************************************/

int32_t mz_zip_set_number_entry(void *handle, uint64_t number_entry);
int32_t mz_zip_get_number_entry(void *handle, uint64_t *number_entry);
int32_t mz_zip_set_disk_number_with_cd(void *handle, uint32_t disk_number_with_cd);
int32_t mz_zip_get_disk_number_with_cd(void *handle, uint32_t *disk_number_with_cd);
int64_t mz_zip_get_entry(void *handle);
int32_t mz_zip_goto_entry(void *handle, int64_t cd_pos);
int32_t mz_zip_goto_first_entry(void *handle);
int32_t mz_zip_goto_next_entry(void *handle);
int32_t mz_zip_locate_entry(void *handle, const char *filename, uint8_t ignore_case);
int32_t mz_zip_locate_first_entry(void *handle, void *userdata, mz_zip_locate_entry_cb cb);
int32_t mz_zip_locate_next_entry(void *handle, void *userdata, mz_zip_locate_entry_cb cb);

/***************************************************************************/

int32_t mz_zip_attrib_is_dir(uint32_t attrib, int32_t version_madeby);
int32_t mz_zip_attrib_is_symlink(uint32_t attrib, int32_t version_madeby);
int32_t mz_zip_attrib_convert(uint8_t src_sys, uint32_t src_attrib, uint8_t target_sys, uint32_t *target_attrib);
int32_t mz_zip_attrib_posix_to_win32(uint32_t posix_attrib, uint32_t *win32_attrib);
int32_t mz_zip_attrib_win32_to_posix(uint32_t win32_attrib, uint32_t *posix_attrib);

/***************************************************************************/

int32_t mz_zip_extrafield_find(void *stream, uint16_t type, uint16_t *length);
int32_t mz_zip_extrafield_contains(const uint8_t *extrafield, int32_t extrafield_size, uint16_t type, uint16_t *length);
int32_t mz_zip_extrafield_read(void *stream, uint16_t *type, uint16_t *length);
int32_t mz_zip_extrafield_write(void *stream, uint16_t type, uint16_t length);

/***************************************************************************/

int32_t  mz_zip_dosdate_to_tm(uint64_t dos_date, struct tm *ptm);
time_t   mz_zip_dosdate_to_time_t(uint64_t dos_date);
int32_t  mz_zip_time_t_to_tm(time_t unix_time, struct tm *ptm);
uint32_t mz_zip_time_t_to_dos_date(time_t unix_time);
uint32_t mz_zip_tm_to_dosdate(const struct tm *ptm);
int32_t  mz_zip_ntfs_to_unix_time(uint64_t ntfs_time, time_t *unix_time);
int32_t  mz_zip_unix_to_ntfs_time(time_t unix_time, uint64_t *ntfs_time);

/***************************************************************************/

int32_t  mz_zip_path_compare(const char *path1, const char *path2, uint8_t ignore_case);

/***************************************************************************/
]]
