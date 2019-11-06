---
tagline: HMAC hashing
---

## `local hmac = require'hmac'`

[HMAC][hmac wiki] algorithm per [RFC 2104].

[hmac wiki]:  http://en.wikipedia.org/wiki/HMAC
[RFC 2104]:   http://tools.ietf.org/html/rfc2104

------------------------------------------------------- -------------------------------------------------------
`hmac.compute(key, message, hash_function,              Compute a hmac hash based on a hash function. Any function that
 blocksize[, opad][, ipad]) -> hash, opad, ipad`        takes a string as single argument works, like `md5.sum`.
																	     `blocksize` is that of the underlying hash function,
																		  i.e. 64 for MD5 and SHA-256, 128 for SHA-384 and SHA-512.
`hmac.new(hash_function, block_size) -> hmac_function`  Returns a HMAC function that can be used with a specific hash function.
`hmac_function(message, key) -> hash`

`hmac.md5   (message, key) -> HMAC-MD5 hash`            Compute HMAC-MD5 (requires [md5]).
`hmac.sha1  (message, key) -> HMAC-SHA256 hash`         Compute HMAC-SHA1 (requires [sha1]).
`hmac.sha256(message, key) -> HMAC-SHA256 hash`         Compute HMAC-SHA256 (requires [sha2]).
`hmac.sha384(message, key) -> HMAC-SHA384 hash`         Compute HMAC-SHA384 (requires [sha2]).
`hmac.sha512(message, key) -> HMAC-SHA512 hash`         Compute HMAC-SHA512 (requires [sha2]).
------------------------------------------------------- -------------------------------------------------
