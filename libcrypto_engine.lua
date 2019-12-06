
require'libcrypto_engine_h'
local M = require'libcrypto'
local C = M.C

function M.ENGINE_load_openssl() return C.OPENSSL_init_crypto(C.OPENSSL_INIT_ENGINE_OPENSSL, nil) end
function M.ENGINE_load_dynamic() return C.OPENSSL_init_crypto(C.OPENSSL_INIT_ENGINE_DYNAMIC, nil) end
function M.ENGINE_load_cryptodev() return C.OPENSSL_init_crypto(OPENSSL_INIT_ENGINE_CRYPTODEV, nil) end
function M.ENGINE_load_rdrand() return C.OPENSSL_init_crypto(C.OPENSSL_INIT_ENGINE_RDRAND, nil) end
function M.ENGINE_get_ex_new_index(...) return C.CRYPTO_get_ex_new_index(...) end

return M
