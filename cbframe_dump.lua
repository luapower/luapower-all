local ffi = require'ffi'
local cbframe = require'cbframe'

local EFLAGS = {
	title = 'EFLAGS', stitle = 'EFLAGS', mdfield = 'EFLAGS',
	fields = {'CF', 'PF', 'AF', 'ZF', 'SF', 'TF', 'IF', 'DF', 'OF',
				'IOPL', 'NT', 'RF', 'VM', 'AC', 'VIF', 'VIP', 'ID'},
	descr = {
		CF    = 'Carry',
		PF    = 'Parity',
		AF    = 'Auxiliary carry',
		ZF    = 'Zero',
		SF    = 'Sign',
		TF    = 'Trap',
		IF    = 'Interrupt enable',
		DF    = 'Direction',
		OF    = 'Overflow',
		IOPL  = 'I/O Priviledge level',
		NT    = 'Nested task',
		RF    = 'Resume',
		VM    = 'Virtual 8086 mode',
		AC    = 'Alignment check',
		VIF   = 'Virutal interrupt',
		VIP   = 'Virtual interrupt pending',
		ID    = 'ID',
	},
}

local FSW = {
	title = 'FPU STATUS WORD', stitle = 'FSW', mdfield = 'FSW',
	fields = {'I', 'D', 'Z', 'O', 'U', 'P', 'SF', 'IR', 'C0', 'C1', 'C2', 'TOP', 'C3', 'B'},
	descr = {
		I   = 'Invalid operation exception',
		D   = 'Denormalized exception',
		Z   = 'Zero divide exception',
		O   = 'Overflow exception',
		U   = 'Underflow exception',
		P   = 'Precision exception',
		SF  = 'Stack Fault exception',
		IR  = 'Interrupt Request',
		C0  = 'C0',
		C1  = 'C1',
		C2  = 'C2',
		TOP = 'TOP',
		C3  = 'C3',
		B   = 'Busy',
	},
}

local FCW = {
	title = 'FPU CONTROL WORD', stitle = 'FCW', mdfield = 'FCW',
	fields = {'IM', 'DM', 'ZM', 'OM', 'UM', 'PM', 'IEM', 'PC', 'RC', 'IC'},
	descr = {
		IM  = 'Invalid operation mask',
		DM  = 'Denormalized operand mask',
		ZM  = 'Zero divide mask',
		OM  = 'Overflow mask',
		UM  = 'Underflow mask',
		PM  = 'Precision mask',
		IEM = 'Interrupt Enable mask',
		PC  = 'Precision Control mask',
		RC  = 'Rounding Control mask',
		IC  = 'Infinity Control mask',
	},
}

local MXCSR = {
	title = 'SSE CONTROL/STATUS FLAG', stitle = 'MXCSR', mdfield = 'MXCSR',
	fields = {'IE', 'DE', 'ZE', 'OE', 'UE', 'PE', 'DAZ', 'IM',
				'DM', 'ZM', 'OM', 'UM', 'PM', 'RM', 'FZ'},
	descr = {
		FZ	 = 'Flush To Zero',
		RM  = 'Round Mode',
		PM  = 'Precision Mask',
		UM  = 'Underflow Mask',
		OM  = 'Overflow Mask',
		ZM  = 'Divide By Zero Mask',
		DM  = 'Denormal Mask',
		IM  = 'Invalid Operation Mask',
		DAZ = 'Denormals Are Zero',
		PE  = 'Precision Flag',
		UE  = 'Underflow Flag',
		OE  = 'Overflow Flag',
		ZE  = 'Divide By Zero Flag',
		DE  = 'Denormal Flag',
		IE  = 'Invalid Operation Flag',
	},
}

local x64 = ffi.arch == 'x64'
local _ = string.format
local out = function(...) io.stdout:write(...) end
local s = ('-'):rep(100)
local outln = function(...) out(...); out'\n' end
local hr = function() outln(s) end

--https://github.com/Itseez/opencv/blob/master/modules/core/include/opencv2/core/cvdef.h
local function isnan(q)
	return bit.band(q.hi.u, 0x7fffffff) + (q.lo.u ~= 0 and 1 or 0) > 0x7ff00000
end

local function isnanf(d)
	return bit.band(d.u, 0x7fffffff) + (d.lo.u ~= 0 and 1 or 0) > 0x7ff00000
end

function cbframe.dump(cpu, opt_)
	local opt = {flags = false, qxmm = x64, qstack = x64}
	if opt_ then for k,v in pairs(opt_) do opt[k] = v end end

	local function out_qwords(qwords)
		local fmt = '%-8s 0x%08x%08x %12s %16d %16d %12s %12s'
		outln(_(            '%-8s %-18s %12s %16s %16s %12s %12s',
			'', 'hex', 'double', 'int32.1', 'int32.0', 'float.1', 'float.0'))
		hr()
		for name, qword in qwords() do
			outln(_(fmt, name,
				qword.hi.u,
				qword.lo.u,
				isnan(qword) and 'nan' or _('%12g', qword.f),
				qword.hi.i,
				qword.lo.i,
				isnanf(qword.hi) and 'nan' or _('%12g', qword.hi.f),
				isnanf(qword.lo) and 'nan' or _('%12g', qword.lo.f)))
		end
		outln()
	end

	local function out_dwords(dwords)
		local fmt = '%-8s 0x%08x %16d %19s %8d %8d %4d %4d %4d %4d'
		outln(_(       '%-8s   %-8s %16s %19s %8s %8s %4s %4s %4s %4s',
			'', 'hex', 'int64', 'float', 'int16.1', 'int16.0', 'b3', 'b2', 'b1', 'b0'))
		hr()
		for name, dword in dwords() do
			outln(_(fmt, name,
				dword.u,
				dword.i,
				isnanf(dword) and 'nan' or _('%19g', dword.f),
				dword.hi.i,
				dword.lo.i,
				dword.hi.hi.i,
				dword.hi.lo.i,
				dword.lo.hi.i,
				dword.lo.lo.i))
		end
		outln()
	end

	local cpu_regs = x64 and {
		'RAX', 'RBX', 'RCX', 'RDX',
		'RSI', 'RDI', 'RBP', 'RSP',
		'R8', 'R9', 'R10', 'R11', 'R12', 'R13', 'R14', 'R15',
	} or {
		'EAX', 'EBX', 'ECX', 'EDX',
		'ESI', 'EDI', 'EBP', 'ESP',
	}

	local function out_gpr(cpu)
		local out_words = x64 and out_qwords or out_dwords
		out_words(function()
			local i = 0
			return function()
				i = i + 1
				if not cpu_regs[i] then return end
				return cpu_regs[i]:lower(), cpu[cpu_regs[i]]
			end
		end)
	end

	local function out_xmm(cpu, q)
		local out_words = q and out_qwords or out_dwords
		out_words(function()
			return coroutine.wrap(function()
				local n = x64 and 16 or 8
				for i=0,n-1 do
					if q then
						for j=0,1 do coroutine.yield('xmm'..i..'.q'..j, cpu.XMM[i].qwords[j]) end
					else
						for j=0,3 do coroutine.yield('xmm'..i..'.d'..j, cpu.XMM[i].dwords[j]) end
					end
				end
			end)
		end)
	end

	local function out_stack(cpu, q)
		local out_words = q and out_qwords or out_dwords
		out_words(function()
			local i = -1
			local esp = cpu[x64 and 'RSP' or 'ESP'][q and 'qp' or 'dp']
			local ebp = cpu[x64 and 'RBP' or 'EBP'][q and 'qp' or 'dp']
			local n = ebp - esp
			return function()
				i = i + 1
				if i >= math.min(n, 32) then return end
				local name = _((x64 and 'r' or 'e')..'sp+%d', i * (q and 8 or 4))
				return name, esp[i]
			end
		end)
	end

	local function getbit(n, v)
		return bit.band(v, bit.lshift(1, n)) ~= 0
	end

	local function tohex(s, upper)
		return (s:gsub('.', function(c)
		  return string.format('%02x', string.byte(c))
		end))
	end

	local function out_streg(cpu, n, k)
		if not getbit(7-n, cpu.FTWX.val) then return end
		outln(_('st(%d)   ', n), _('%s    ', tohex(ffi.string(cpu.FPR[k].bytes, 10))),
			_('%g', cbframe.float80to64(cpu.FPR[k].b)))
	end

	local function out_fpr(cpu)
		hr()
		for i=0,7 do
			out_streg(cpu, i, i)
		end
		outln()
	end

	local function flag_dumper(def)
		local function longdump(cpu)
			outln(_('%s:', def.title))
			hr()
			local mdfield = type(def.mdfield) == 'string' and cpu[def.mdfield] or def.mdfield(cpu)
			for i,name in ipairs(def.fields) do
				outln(_('%-8s', name), _('%-8d', mdfield[name]), def.descr[name])
			end
			outln()
		end
		local function shortdump(cpu)
			out(_('%-5s ', def.stitle))
			local mdfield = type(def.mdfield) == 'string' and cpu[def.mdfield] or def.mdfield(cpu)
			for i,name in ipairs(def.fields) do
				out(_('%-2s=%d ', name, mdfield[name]))
			end
			outln()
		end
		return function(cpu, long)
			if long then longdump(cpu) else shortdump(cpu) end
		end
	end

	local out_eflags = flag_dumper(EFLAGS)
	local out_fsw    = flag_dumper(FSW)
	local out_fcw    = flag_dumper(FCW)
	local out_mxcsr  = flag_dumper(MXCSR)

	out_gpr(cpu)
	out_fpr(cpu)
	out_xmm(cpu, opt.qxmm)
	out_stack(cpu, opt.qstack)

	if opt.flags then
		out_eflags(cpu)
		out_mxcsr(cpu)
		out_fsw(cpu)
		out_fcw(cpu)
	end
end

if not ... then
	local cpu = ffi.new'D_CPUSTATE'
	local stack
	if x64 then
		stack = ffi.new'D_QWORD[4]'
		cpu.RSP.p = stack
		cpu.RBP.p = stack + 4
	else
		stack = ffi.new'D_DWORD[4]'
		cpu.ESP.p = stack
		cpu.EBP.p = stack + 4
	end
	stack[0].u = 22224444
	stack[2].u = 0xABCDEF
	stack[3].f = math.pi
	cpu.EAX.u = 12345
	cpu.ESI.u = 67890
	cpu.XMM[3].lo.f    = math.pi
	cpu.XMM[4].lo.lo.f = math.pi
	cpu.XMM[5].lo.lo.u = 123456
	cpu.XMM[5].lo.hi.u = 789012
	cpu.XMM[5].hi.lo.u = 120987
	cpu.XMM[5].hi.hi.u = 654321
	cbframe.float64to80(1/16,   cpu.FPR[3].b); cpu.FTWX.FP3 = 1
	cbframe.float64to80(1e-234, cpu.FPR[5].b); cpu.FTWX.FP5 = 1
	cbframe.dump(cpu, {flags = true})
end

