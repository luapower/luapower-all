--HMAC-SHA1 implementation
--hmac.sha1(message, key) -> HMAC-SHA1 string

local hmac = require 'hmac'
local sha1 = require 'sha1'

hmac.sha1 = hmac.new(sha2.sha1, 64)

if not ... then require'hmac_sha1_test' end
