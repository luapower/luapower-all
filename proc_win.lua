
local ffi = require'ffi'
local bit = require'bit'
assert(ffi.os == 'Windows', 'platform not Windows')

local M = {}
local proc = {type = 'process', debug_prefix = 'P'}

--TODO: move relevant ctypes here and get rid of the winapi dependency
--(not worth it unless you are really really bored).
local winapi = require'winapi'
require'winapi.process'
require'winapi.thread'

--see https://docs.microsoft.com/en-us/archive/blogs/twistylittlepassagesallalike/everyone-quotes-command-line-arguments-the-wrong-way
--You will lose precious IQ points if you read that. Lose enough of them
--and you might get a job at Microsoft!
function M.esc_win(s) --escape for putting inside double-quoted string
	s = tostring(s)
	if not s:find'[\\"]' then
		return s
	end
	s = s:gsub('(\\*)"', function(s) return s:rep(2)..'\\"' end)
	s = s:gsub('\\+$', function(s) return s:rep(2) end)
	return s
end

function M.quote_path_win(s)
	if s:find'%s' then
		s = '"'..s..'"'
	end
	return s
end

function M.quote_arg_win(s)
	s = tostring(s)
	if not s:find'[ \t\n\v"^&<>|]' then
		return s
	else
		return '"'..M.esc_win(s)..'"'
	end
end

function M.env(k, v)
	if k then
		if v ~= nil then
			assert(winapi.SetEnvironmentVariable(k, v))
		else
			return winapi.GetEnvironmentVariable(k)
		end
	end
	local t = {}
	for i,s in ipairs(winapi.GetEnvironmentStrings()) do
		local k,v = s:match'^([^=]*)=(.*)'
		if k and k ~= '' then --the first two ones are internal and invalid.
			t[k] = v
		end
	end
	return t
end

local autokill_job

local error_classes = {
	[0x002] = 'not_found', --ERROR_FILE_NOT_FOUND
	[0x005] = 'access_denied', --ERROR_ACCESS_DENIED
}

function M.exec(cmd, env, dir, stdin, stdout, stderr, autokill, async, inherit_handles)

	if type(cmd) == 'table' then
		local t = {}
		t[1] = M.quote_path_win(cmd[1])
		for i = 2, #cmd do
			t[i] = M.quote_arg_win(cmd[i])
		end
		cmd = table.concat(t, ' ')
	end

	local inp_rf, inp_wf
	local out_rf, out_wf
	local err_rf, err_wf

	local self = setmetatable({async = async}, {__index = proc})

	local function close_all()
		if self.stdin then
			assert(inp_rf:close())
			assert(inp_wf:close())
		end
		if self.stdout then
			assert(out_rf:close())
			assert(out_wf:close())
		end
		if self.stderr then
			assert(err_rf:close())
			assert(err_wf:close())
		end
	end

	if async then
		local sock = require'sock'
		self._sleep = sock.sleep
		self._clock = sock.clock
	else
		local time = require'time'
		self._sleep = time.sleep
		self._clock = time.clock
	end

	local si

	if stdin or stdout or stderr then

		if stdin == true then
			local fs = require'fs'
			inp_rf, inp_wf = fs.pipe{
				write_async = async,
				read_inheritable = true,
			}
			if not inp_rf then
				close_all()
				return nil, inp_wf
			end
			self.stdin = inp_wf
		elseif stdin then
			assert(stdin.type == 'pipe')
			stdin:set_inheritable(true)
			inp_rf = stdin
		end

		if stdout == true then
			local fs = require'fs'
			out_rf, out_wf = fs.pipe{
				read_async = async,
				write_inheritable = true,
			}
			if not out_rf then
				close_all()
				return nil, out_wf
			end
			self.stdout = out_rf
		elseif stdout then
			assert(stdout.type == 'pipe')
			stdout:set_inheritable(true)
			out_wf = stdout
		end

		if stderr == true then
			local fs = require'fs'
			err_rf, err_wf = fs.pipe{
				read_async = async,
				write_inheritable = true,
			}
			if not err_rf then
				close_all()
				return nil, err_wf
			end
			self.stderr = err_rf
		elseif stderr then
			assert(stderr.type == 'pipe')
			stderr:set_inheritable(true)
			err_wf = stderr
		end

		si = winapi.STARTUPINFO()
		si.hStdInput  = inp_rf and inp_rf.handle or winapi.GetStdHandle(winapi.STD_INPUT_HANDLE)
		si.hStdOutput = out_wf and out_wf.handle or winapi.GetStdHandle(winapi.STD_OUTPUT_HANDLE)
		si.hStdError  = err_wf and err_wf.handle or winapi.GetStdHandle(winapi.STD_ERROR_HANDLE)
		si.dwFlags = winapi.STARTF_USESTDHANDLES

		--NOTE: there's no way to inherit only the std handles: all handles
		--declared inheritable in the parent process will be inherited!
		inherit_handles = true
	end

	if autokill and not autokill_job then
		autokill_job = winapi.CreateJobObject()
		local jeli = winapi.JOBOBJECT_EXTENDED_LIMIT_INFORMATION()
		jeli.BasicLimitInformation.LimitFlags = winapi.JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
		winapi.SetInformationJobObject(autokill_job, winapi.C.JobObjectExtendedLimitInformation, jeli)
	end

	local is_in_job = autokill and winapi.IsProcessInJob(winapi.GetCurrentProcess(), nil)

	if _G.note then
		note('proc', 'exec', '%s', cmd)
	end

	local pi, err, errcode = winapi.CreateProcess(
		cmd, env, dir, si, inherit_handles,
			autokill
				and bit.bor(
					winapi.CREATE_SUSPENDED, --so we can add it to a job before it starts
					is_in_job and winapi.CREATE_BREAKAWAY_FROM_JOB or 0
				)
				or nil)

	if not pi then
		close_all()
		return nil, error_classes[errcode] or err
	end

	if autokill then
		winapi.AssignProcessToJobObject(autokill_job, pi.hProcess)
		winapi.ResumeThread(pi.hThread)
	end

	--Let the child process have the only handles to their pipe ends,
	--otherwise when the child process exits, the pipes will stay open on
	--account of us (the parent process) holding a handle to them.
	if inp_rf then assert(inp_rf:close()) end
	if out_wf then assert(out_wf:close()) end
	if err_wf then assert(err_wf:close()) end

	self.handle             = pi.hProcess
	self.main_thread_handle = pi.hThread
	self.id                 = pi.dwProcessId
	self.main_thread_id     = pi.dwThreadId

	return self
end

function proc:forget()
	if self.stdin  then assert(self.stdin :close()) end
	if self.stdout then assert(self.stdout:close()) end
	if self.stderr then assert(self.stderr:close()) end
	if self.handle then
		assert(winapi.CloseHandle(self.handle))
		assert(winapi.CloseHandle(self.main_thread_handle))
		self.handle = false
		self.id = false
		self.main_thread_handle = false
		self.main_thread_id = false
	end
end

--compound the STILL_ACTIVE hack with another hack to signal killed status.
local EXIT_CODE_KILLED = winapi.STILL_ACTIVE + 1

function proc:kill()
	if not self.handle then
		return nil, 'forgotten'
	end
	return winapi.TerminateProcess(self.handle, EXIT_CODE_KILLED)
end

function proc:exit_code()
	if self._exit_code then
		return self._exit_code
	elseif self._killed then
		return nil, 'killed'
	end
	if not self.handle then
		return nil, 'forgotten'
	end
	local exitcode = winapi.GetExitCodeProcess(self.handle)
	if not exitcode then
		return nil, 'active'
	end
	--save the exit status so we can forget the process.
	if exitcode == EXIT_CODE_KILLED then
		self._killed = true
	else
		self._exit_code = exitcode
	end
	return self:exit_code()
end

function proc:wait(expires)
	if not self.handle then
		return nil, 'forgotten'
	end
	while self:status() == 'active' and self._clock() < (expires or 1/0) do
		self._sleep(.1)
	end
	local exit_code, err = self:exit_code()
	if exit_code then
		return exit_code
	else
		return nil, err
	end
end

function proc:status() --finished | killed | active | forgotten
	local code, err = self:exit_code()
	return code and 'finished' or err
end

return M
