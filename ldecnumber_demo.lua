local decnumber = require'ldecnumber'

local balance = decnumber.tonumber'0.00'

balance = balance + '0.01'
balance = balance + '1.25'
balance = balance - '1.12'

assert(balance:isfinite() == true)
assert(balance:isinfinite() == false)
assert(balance:isnan() == false)

assert(balance:tostring() == '0.14')
