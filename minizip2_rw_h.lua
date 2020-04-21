--mz_zip_rw.h 2.9.1 Zip reader/writer
require'minizip2_h'
require'minizip2_strm_h'
local ffi = require'ffi'
ffi.cdef[[

/***************************************************************************/

typedef int32_t (*mz_zip_reader_overwrite_cb)(void *handle, void *userdata, mz_zip_file *file_info, const char *path);
typedef int32_t (*mz_zip_reader_password_cb)(void *handle, void *userdata, mz_zip_file *file_info, char *password, int32_t max_password);
typedef int32_t (*mz_zip_reader_progress_cb)(void *handle, void *userdata, mz_zip_file *file_info, int64_t position);
typedef int32_t (*mz_zip_reader_entry_cb)(void *handle, void *userdata, mz_zip_file *file_info, const char *path);

/***************************************************************************/

int32_t mz_zip_reader_open(void *handle, void *stream);
int32_t mz_zip_reader_open_file(void *handle, const char *path);
int32_t mz_zip_reader_open_file_in_memory(void *handle, const char *path);
int32_t mz_zip_reader_open_buffer(void *handle, uint8_t *buf, int32_t len, uint8_t copy);
int32_t mz_zip_reader_close(void *handle);

/***************************************************************************/

int32_t mz_zip_reader_unzip_cd(void *handle);

/***************************************************************************/

int32_t mz_zip_reader_goto_first_entry(void *handle);
int32_t mz_zip_reader_goto_next_entry(void *handle);
int32_t mz_zip_reader_locate_entry(void *handle, const char *filename, uint8_t ignore_case);
int32_t mz_zip_reader_entry_open(void *handle);
int32_t mz_zip_reader_entry_close(void *handle);
int32_t mz_zip_reader_entry_read(void *handle, void *buf, int32_t len);
int32_t mz_zip_reader_entry_has_sign(void *handle);
int32_t mz_zip_reader_entry_sign_verify(void *handle);
int32_t mz_zip_reader_entry_get_hash(void *handle, uint16_t algorithm, uint8_t *digest, int32_t digest_size);
int32_t mz_zip_reader_entry_get_first_hash(void *handle, uint16_t *algorithm, uint16_t *digest_size);
int32_t mz_zip_reader_entry_get_info(void *handle, mz_zip_file **file_info);
int32_t mz_zip_reader_entry_is_dir(void *handle);
int32_t mz_zip_reader_entry_save(void *handle, void *stream, mz_stream_write_cb write_cb);
int32_t mz_zip_reader_entry_save_process(void *handle, void *stream, mz_stream_write_cb write_cb);
int32_t mz_zip_reader_entry_save_file(void *handle, const char *path);
int32_t mz_zip_reader_entry_save_buffer(void *handle, void *buf, int32_t len);
int32_t mz_zip_reader_entry_save_buffer_length(void *handle);

/***************************************************************************/

int32_t mz_zip_reader_save_all(void *handle, const char *destination_dir);

/***************************************************************************/

void    mz_zip_reader_set_pattern(void *handle, const char *pattern, uint8_t ignore_case);
void    mz_zip_reader_set_password(void *handle, const char *password);
void    mz_zip_reader_set_raw(void *handle, uint8_t raw);
int32_t mz_zip_reader_get_raw(void *handle, uint8_t *raw);
int32_t mz_zip_reader_get_zip_cd(void *handle, uint8_t *zip_cd);
int32_t mz_zip_reader_get_comment(void *handle, const char **comment);
void    mz_zip_reader_set_encoding(void *handle, int32_t encoding);
void    mz_zip_reader_set_sign_required(void *handle, uint8_t sign_required);
void    mz_zip_reader_set_overwrite_cb(void *handle, void *userdata, mz_zip_reader_overwrite_cb cb);
void    mz_zip_reader_set_password_cb(void *handle, void *userdata, mz_zip_reader_password_cb cb);
void    mz_zip_reader_set_progress_cb(void *handle, void *userdata, mz_zip_reader_progress_cb cb);
void    mz_zip_reader_set_progress_interval(void *handle, uint32_t milliseconds);
void    mz_zip_reader_set_entry_cb(void *handle, void *userdata, mz_zip_reader_entry_cb cb);
int32_t mz_zip_reader_get_zip_handle(void *handle, void **zip_handle);
void*   mz_zip_reader_create(void **handle);
void    mz_zip_reader_delete(void **handle);

/***************************************************************************/

typedef int32_t (*mz_zip_writer_overwrite_cb)(void *handle, void *userdata, const char *path);
typedef int32_t (*mz_zip_writer_password_cb)(void *handle, void *userdata, mz_zip_file *file_info, char *password, int32_t max_password);
typedef int32_t (*mz_zip_writer_progress_cb)(void *handle, void *userdata, mz_zip_file *file_info, int64_t position);
typedef int32_t (*mz_zip_writer_entry_cb)(void *handle, void *userdata, mz_zip_file *file_info);

/***************************************************************************/

int32_t mz_zip_writer_open(void *handle, void *stream);
int32_t mz_zip_writer_open_file(void *handle, const char *path, int64_t disk_size, uint8_t append);
int32_t mz_zip_writer_open_file_in_memory(void *handle, const char *path);
int32_t mz_zip_writer_close(void *handle);

/***************************************************************************/

int32_t mz_zip_writer_zip_cd(void *handle);

/***************************************************************************/

int32_t mz_zip_writer_entry_open(void *handle, mz_zip_file *file_info);
int32_t mz_zip_writer_entry_close(void *handle);
int32_t mz_zip_writer_entry_write(void *handle, const void *buf, int32_t len);
int32_t mz_zip_writer_entry_sign(void *handle, uint8_t *message, int32_t message_size, uint8_t *cert_data, int32_t cert_data_size, const char *cert_pwd);

/***************************************************************************/

int32_t mz_zip_writer_add(void *handle, void *stream, mz_stream_read_cb read_cb);
int32_t mz_zip_writer_add_process(void *handle, void *stream, mz_stream_read_cb read_cb);
int32_t mz_zip_writer_add_info(void *handle, void *stream, mz_stream_read_cb read_cb, mz_zip_file *file_info);
int32_t mz_zip_writer_add_buffer(void *handle, void *buf, int32_t len, mz_zip_file *file_info);
int32_t mz_zip_writer_add_file(void *handle, const char *path, const char *filename_in_zip);
int32_t mz_zip_writer_add_path(void *handle, const char *path, const char *root_path, uint8_t include_path, uint8_t recursive);

int32_t mz_zip_writer_copy_from_reader(void *handle, void *reader);

/***************************************************************************/

void    mz_zip_writer_set_password(void *handle, const char *password);
void    mz_zip_writer_set_comment(void *handle, const char *comment);
void    mz_zip_writer_set_raw(void *handle, uint8_t raw);
int32_t mz_zip_writer_get_raw(void *handle, uint8_t *raw);
void    mz_zip_writer_set_aes(void *handle, uint8_t aes);
void    mz_zip_writer_set_compress_method(void *handle, uint16_t compress_method);
void    mz_zip_writer_set_compress_level(void *handle, int16_t compress_level);
void    mz_zip_writer_set_follow_links(void *handle, uint8_t follow_links);
void    mz_zip_writer_set_store_links(void *handle, uint8_t store_links);
void    mz_zip_writer_set_zip_cd(void *handle, uint8_t zip_cd);
int32_t mz_zip_writer_set_certificate(void *handle, const char *cert_path, const char *cert_pwd);
void    mz_zip_writer_set_overwrite_cb(void *handle, void *userdata, mz_zip_writer_overwrite_cb cb);
void    mz_zip_writer_set_password_cb(void *handle, void *userdata, mz_zip_writer_password_cb cb);
void    mz_zip_writer_set_progress_cb(void *handle, void *userdata, mz_zip_writer_progress_cb cb);
void    mz_zip_writer_set_progress_interval(void *handle, uint32_t milliseconds);
void    mz_zip_writer_set_entry_cb(void *handle, void *userdata, mz_zip_writer_entry_cb cb);
int32_t mz_zip_writer_get_zip_handle(void *handle, void **zip_handle);
void*   mz_zip_writer_create(void **handle);
void    mz_zip_writer_delete(void **handle);

/***************************************************************************/
]]
