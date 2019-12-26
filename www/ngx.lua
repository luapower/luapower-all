
--entry point for all urls that are not static files.
--set the module paths and run the app module.

--overwrite these because by default, LUA_(C)PATH are appended, not replaced.
package.path = os.getenv'LUA_PATH'
package.cpath = os.getenv'LUA_CPATH'

--global error handler: log and print the error.
local function try_call(func, ...)
	local function pass(ok, ...)
		if ok then return ... end
		local err = tostring(...)
		ngx.log(ngx.ERR, err)
		ngx.status = 500
		ngx.header.content_type = 'text/plain'
		ngx.say(err)
		ngx.exit(0)
	end
	return pass(xpcall(func, debug.traceback, ...))
end

local app = try_call(require, 'app')
try_call(app.run)
