
## `local zip = require'minizip2'`

A ffi binding of minizip2, a C library for creating and extracting zip
archives, featuring:

  * reading and writing zip archives from memory.
  * password protection with AES encryption.
  * preserving file attributes and timestamps across file systems.
  * multi-file archives.
  * following and storing symbolic links.
  * utf8 filename support.
  * zipping of central directory to reduce size.
  * generate and verify CMS file signatures.
  * recover the central directory if it is corrupt or missing.

## API

---------------------------------------------------- -------------------------------------------
`zip.open(opt | file,[mode],[passwd]) -> rz|wz`      open a zip file
`rz:entries() -> iter() -> e`                        iterate entries
`rz:first() -> true|false`                           goto first entry
`rz:next() -> true|false`                            goto next entry
`rz:find(filename[, ignore_case]) -> true|false`     find entry
`rz.entry_is_dir -> true|false`                      is current entry a directory?
`rz:entry_hash(['md5'|'sha1'|'sha256']) -> s|false`  current entry hash
`rz.sign_required = true|false`                      require signing
`rz.file_has_sign -> true|false`                     is _opened *file* entry_ signed?
`rz:file_verify_sign() -> true|false`                verify signature of _opened file entry_
`rz.entry -> e`                                      get current entry info
`e.compression_method -> s`                          compression method
`e.mtime -> ts`                                      last modified time
`e.atime -> ts`                                      last accessed time
`e.btime -> ts`                                      creation time
`e.crc -> n`                                         crc-32
`e.compressed_size -> n`                             compressed size
`e.uncompressed_size -> n`                           uncompressed size
`e.disk_number -> n`                                 disk number start
`e.disk_offset -> n`                                 relative offset of local header
`e.internal_fa -> n`                                 internal file attributes
`e.external_fa -> n`                                 external file attributes
`e.filename -> s`                                    filename
`e.comment -> s`                                     comment
`e.linkname -> s`                                    sym-link filename
`e.zip64 -> true|false`                              zip64 extension mode
`e.aes_version -> n`                                 winzip aes extension if not 0
`e.aes_encryption_mode -> n`                         winzip aes encryption mode
`rz:extract(to_filepath)`                            extract current entry to file
`rz:extract_all(to_dir)`                             extract all to dir
`rz:read'*a' -> s`                                   read entire entry as string
`rz:open_entry()`                                    open current entry
`rz:read(buf, maxlen) -> len`                        read from opened entry into a buffer
`rz:close_entry()`                                   close entry
`rz.pattern = s`                                     filter listing entries
`rz.ci_pattern = s`                                  filter listing entries (case insensitive)
`rz|wz.password = s`                                 set password for decryption/encryption
`rz|wz.raw = true|false`                             set raw mode
`rz|wz.raw -> true|false`                            get raw mode
`rz.encoding = 'utf8'|codepage`                      support codepages in filenames
`rz.zip_cd -> true|false`                            does the zip have a zipped central directory?
`wz.zip_cd = true|false`                             zip the central directory
`rz.comment -> s`                                    get comment for the central directory
`wz.aes = true|false`                                use aes encryption
`wz.store_links = true|false`                        store symlinks
`wz.follow_links = true|false`                       follow symlinks
`wz.compression_level = 0..9`                        set compression level
`wz.compression_method = 'store|deflate'`            set compression method
`wz:add_file(filepath[, filepath_in_zip])`           archive a file
`wz:add_memfile{filename=,data=,[size=],...}`        add a file from a memory buffer
`wz:add_all(dir,[root_dir],[incl_path],[recursive])` add entire dir
`wz:add_all_from_zip(rz)`                            add all entries from other zip file
`wz:zip_cd()`                                        compress central directory
`wz:set_cert(cert_path[, password])`                 set signing certificate
`rz|wz.zip_handle -> z`                              get C zip handle
`rz|wz:close()`                                      close the zip file
---------------------------------------------------- -------------------------------------------

__NOTE:__ All functions raise on errors, with the exception of I/O and parsing
errors on which they return `nil, err, errcode`.

### `zip.open(options | file,[mode],[passwd]) -> rz|wz`

The options table has the fields:

--------------------- -------- ----------------- ------------ --------------------------------------------------
__key__               __mode__ __value__         __default__  __meaning__
`mode`                rwa      `'r'|'w'|'a'`     `'r'`        open for reading, writing or appending
`file`                rwa      `string`                       open a zip file from disk
`in_memory`           r        `true|false`      `false`      load whole file in memory
`data`                r        `string|buffer`                open a zip file from a memory buffer or string
`size`                r        `number`          `#data`      data size
`copy`                r        `true|false`      `false`      copy the buffer before loading
`pattern`             r        `string`                       filter listing entries
`ci_pattern`          r        `string`                       filter listing entries (case insensitive)
`password`            rwa      `string`                       set password for decryption/encryption
`raw`                 rwa      `true|false`                   set raw mode
`encoding`            r        `'utf8'|codepage`              support codepages in filenames
`zip_cd`              w        `true|false`      `false`      zip the central directory
`aes`                 w        `true|false`      `true` (!)   use aes encryption
`store_links`         w        `true|false`      `false`      store symlinks
`follow_links`        w        `true|false`      `false`      follow symlinks
`compression_level`   w        `0..9`            `9`          compression level
`compression_method`  w        `'store|deflate'` `'deflate'`  compression method
--------------------- -------- ----------------- ------------ --------------------------------------------------

Open a zip file for reading, writing or appending. The zip file bits can come
from the filesystem or from a memory buffer.

## Notes

Neither Windows Explorer on Windows 10 nor Total Commander can read zip files
with zipped central directory (`zip_cd` option).

Windows Explorer on Windows 10 cannot read AES-encrypted zip entries
(`aes` option, enabled by default). On the other hand, the old PKZIP
encryption (`aes = false`) is not secure at all, and can be decrypted with
specialized tools since 1990 regardless of password length. So you have
to choose between security and accessibility with this one as you can't
have both.

AES encryption (`aes` option) encrypts with AES-256, the only bit length
available.

## Binaries

The included binaries only support deflate compression for which they
depend on zlib. LZMA and bzip2 compression/decompression is not supported
in the binary (the binding supports it though if you have the right binary).

## TODO

  * stream API (yieldable if possible)
