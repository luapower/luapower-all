local glue = require'glue'
local objc = require'objc'
local ffi = require'ffi'
local pp = require'pp'

io.stdout:setvbuf'no'
io.stderr:setvbuf'no'

setmetatable(_G, {__index = objc})

--test options

local subprocess = false --run each bridgesupport test in a subprocess
objc.debug.lazyfuncs = true
objc.debug.checkredef = false
objc.debug.printcdecl = false
objc.debug.loaddeps = false
objc.debug.loadtypes = true

local bsdir = '_bridgesupport' --path where *.bridgesupport files are on Windows (tree or flat doesn't matter)
local luajit = ffi.os == 'Windows' and 'luajit' or './luajit' --luajit command for subprocess running

if ffi.os == 'OSX' then
	objc.load'Foundation'
	pool = NSAutoreleasePool:new()
end

--test helpers

local function printf(...)
	print(string.format(...))
end

local function hr()
	print(('-'):rep(80))
end

local n = 0
local function genname(prefix)
	if not prefix then return genname'MyClass' end
	n = n + 1
	return prefix..n
end

local function errpcall(patt, ...) --pcall that should fail with a specific message
	local ok, err = pcall(...)
	assert(not ok)
	assert(err:find(patt))
end

--test namespace

local test = {}    --{name = test_func}
local eyetest = {} --{name = test_func}
local demo = {}
local tests = {tests = test, ['eye tests'] = eyetest, demos = demo}

function test.parsing()
	assert(stype_ctype('[8^c]', 'arr') == 'char *arr[8]') --array of pointers
	assert(stype_ctype('^[8c]', 'arr') == 'char (*arr)[8]') --pointer to array
	assert(stype_ctype('[8[4c]]', 'arr') == 'char arr[8][4]') --multi-dim. array
	assert(stype_ctype('[3^[8^c]]', 'arr') == 'char *(*arr[3])[8]')
	assert(stype_ctype('{?="x"i"y"i""(?="ux"I"uy"I)}', nil, 'cdef') ==
		'struct {\n\tint x;\n\tint y;\n\tunion {\n\t\tunsigned int ux;\n\t\tunsigned int uy;\n\t};\n}'
		) --nested unnamed anonymous structs

	local function mtype_ctype(mtype, ...)
		return ftype_ctype(mtype_ftype(mtype), ...)
	end
	assert(mtype_ctype('@"Class"@:{_NSRect={_NSPoint=ff}{_NSSize=ff}}^{?}^?', 'globalFunction') ==
		'id globalFunction (id, SEL, struct _NSRect, void *, void *)') --unseparated method args
	assert(mtype_ctype('{_NSPoint=ff}iii', nil, true) ==
		'void (*) (int, int, int)') --struct return value not supported
	assert(mtype_ctype('iii{_NSPoint=ff}ii', nil, true) ==
		'int (*) (int, int)') --pass-by-value struct not supported, stop at first encounter
	assert(mtype_ctype('{_NSPoint=ff}ii{_NSPoint=ff}i', nil, true) ==
		'void (*) (int, int)') --combined case
end

function eyetest.indent()
	--_NXEvent (test indent for nested unnamed anonymous structs)
	print(stype_ctype('{?="type"i"location"{?="x"i"y"i}"time"Q"flags"i"window"I"service_id"Q"ext_pid"i"data"(?="mouse"{?="subx"C"suby"C"eventNum"s"click"i"pressure"C"buttonNumber"C"subType"C"reserved2"C"reserved3"i"tablet"(?="point"{_NXTabletPointData="x"i"y"i"z"i"buttons"S"pressure"S"tilt"{?="x"s"y"s}"rotation"S"tangentialPressure"s"deviceID"S"vendor1"s"vendor2"s"vendor3"s}"proximity"{_NXTabletProximityData="vendorID"S"tabletID"S"pointerID"S"deviceID"S"systemTabletID"S"vendorPointerType"S"pointerSerialNumber"I"uniqueID"Q"capabilityMask"I"pointerType"C"enterProximity"C"reserved1"s})}"mouseMove"{?="dx"i"dy"i"subx"C"suby"C"subType"C"reserved1"C"reserved2"i"tablet"(?="point"{_NXTabletPointData="x"i"y"i"z"i"buttons"S"pressure"S"tilt"{?="x"s"y"s}"rotation"S"tangentialPressure"s"deviceID"S"vendor1"s"vendor2"s"vendor3"s}"proximity"{_NXTabletProximityData="vendorID"S"tabletID"S"pointerID"S"deviceID"S"systemTabletID"S"vendorPointerType"S"pointerSerialNumber"I"uniqueID"Q"capabilityMask"I"pointerType"C"enterProximity"C"reserved1"s})}"key"{?="origCharSet"S"repeat"s"charSet"S"charCode"S"keyCode"S"origCharCode"S"reserved1"i"keyboardType"I"reserved2"i"reserved3"i"reserved4"i"reserved5"[4i]}"tracking"{?="reserved"s"eventNum"s"trackingNum"i"userData"i"reserved1"i"reserved2"i"reserved3"i"reserved4"i"reserved5"i"reserved6"[4i]}"scrollWheel"{?="deltaAxis1"s"deltaAxis2"s"deltaAxis3"s"reserved1"s"fixedDeltaAxis1"i"fixedDeltaAxis2"i"fixedDeltaAxis3"i"pointDeltaAxis1"i"pointDeltaAxis2"i"pointDeltaAxis3"i"reserved8"[4i]}"zoom"{?="deltaAxis1"s"deltaAxis2"s"deltaAxis3"s"reserved1"s"fixedDeltaAxis1"i"fixedDeltaAxis2"i"fixedDeltaAxis3"i"pointDeltaAxis1"i"pointDeltaAxis2"i"pointDeltaAxis3"i"reserved8"[4i]}"compound"{?="reserved"s"subType"s"misc"(?="F"[11f]"L"[11i]"S"[22s]"C"[44c])}"tablet"{?="x"i"y"i"z"i"buttons"S"pressure"S"tilt"{?="x"s"y"s}"rotation"S"tangentialPressure"s"deviceID"S"vendor1"s"vendor2"s"vendor3"s"reserved"[4i]}"proximity"{?="vendorID"S"tabletID"S"pointerID"S"deviceID"S"systemTabletID"S"vendorPointerType"S"pointerSerialNumber"I"uniqueID"Q"capabilityMask"I"pointerType"C"enterProximity"C"reserved1"s"reserved2"[4i]})}', nil, 'cdef'))
end

function eyetest.tostring()
	print(objc.NSNumber:numberWithDouble(0))
	print(objc.NSString:alloc():initWithUTF8String'') --empty string = NSFConstantString with hi address
	print(objc.NSString:alloc():initWithUTF8String'asdjfah') --real object
end

--test parsing of bridgesupport files.
--works on Windows too - just copy your bridgesupport files into whatever you set `bsdir` above.
function eyetest.bridgesupport(bsfile)

	local function list_func(cmd)
		return function()
			return coroutine.wrap(function()
				local f = io.popen(cmd)
				for s in f:lines() do
					coroutine.yield(s)
				end
				f:close()
			end)
		end
	end

	local bsfiles
	if ffi.os == 'Windows' then
		bsfiles = list_func('dir /B /S '..bsdir..'\\*.bridgesupport')
	elseif ffi.os == 'OSX' then
		bsfiles = list_func('find /System/Library/frameworks -name \'*.bridgesupport\'')
	else
		error'can\'t run on this OS'
	end

	local loaded = {}
	local n = 0

	local objc_load = objc.debug.load_framework --keep it, we'll patch it

	function objc.debug.load_framework(path) --either `name.bridgesupport` or `name.framework` or `name.framework/name`
		local name
		if path:match'%.bridgesupport$' then
			name = path:match'([^/\\]+)%.bridgesupport$'
		else
			name = path:match'/([^/]+)%.framework$' or path:match'([^/]+)$'
			if ffi.os == 'Windows' then
				path = bsdir..'\\'..name..'.bridgesupport'
			else
				path = path .. '/Resources/BridgeSupport/' .. name .. '.bridgesupport'
			end
		end
		if loaded[name] then return end
		loaded[name] = true
		if glue.fileexists(path) then

			if ffi.os == 'OSX' then

				--load the dylib first (needed for function aliases)
				local dpath = path:gsub('Resources/BridgeSupport/.*$', name)
				if glue.fileexists(dpath) then
					pcall(ffi.load, dpath, true)
				end

				--load the dylib with inlines first (needed for function aliases)
				local dpath = path:gsub('bridgesupport$', 'dylib')
				if glue.fileexists(dpath) then
					pcall(ffi.load, dpath, true)
				end
			end

			objc.debug.load_bridgesupport(path)
			n = n + 1
			--print(n, '', name)
		else
			print('! not found', name, path)
		end
	end

	local function status()
		pp('errors', objc.debug.errcount)
		print('globals:  '..objc.debug.cnames.global[1])
		print('structs:  '..objc.debug.cnames.struct[1])
	end

	if bsfile then
		objc.debug.load_framework(bsfile)
	else
		for bsfile in bsfiles() do
			if bsfile:match'Python' then
				print('skipping '..bsfile) --python bridgesupport files are non-standard and deprecated
			else
				--print(); print(bsfile); print(('='):rep(80))
				if subprocess then
					os.execute(luajit..' '..arg[0]..' bridgesupport '..bsfile)
				else
					objc.debug.load_framework(bsfile)
				end
			end
		end
		status()
	end

	objc.debug.load_framework = objc_load --put it back
end

function test.selectors()
	assert(tostring(SEL'se_lec_tor') == 'se:lec:tor')
	assert(tostring(SEL'se_lec_tor_') == 'se:lec:tor:')
	assert(tostring(SEL'__se_lec_tor') == '__se:lec:tor')
	assert(tostring(SEL'__se:lec:tor:') == '__se:lec:tor:')
end

--class, superclass, metaclass, class protocols
function test.class()
	--arg. checking
	errpcall('already',    class, 'NSObject', 'NSString')
	errpcall('superclass', class, genname(), 'MyUnknownClass')
	errpcall('protocol',   class, genname(), 'NSObject <MyUnknownProtocol>')

	--class overloaded constructors
	local cls = class('MyClassX', false) --root class
	assert(classname(cls) == 'MyClassX')
	assert(not superclass(cls))

	--derived class
	local cls = class(genname(), 'NSArray')
	assert(isa(cls, 'NSArray'))

	--derived + conforming
	local cls = class(genname(), 'NSArray <NSStreamDelegate, NSLocking>')
	assert(isa(cls, 'NSArray'))

	assert(conforms(cls, 'NSStreamDelegate'))
	assert(conforms(cls, 'NSLocking'))

	local t = {0}
	for proto in protocols(cls) do
		t[proto:name()] = true
		t[1] = t[1] + 1
	end
	assert(t[1] == 2)
	assert(t.NSStreamDelegate)
	assert(t.NSLocking)

	--class hierarchy queries
	assert(superclass(cls) == NSArray)
	assert(metaclass(cls))
	assert(superclass(metaclass(cls)) == metaclass'NSArray')
	assert(metaclass(superclass(cls)) == metaclass'NSArray')
	assert(metaclass(metaclass(cls)) == nil)
	assert(isa(cls, 'NSObject'))
	assert(ismetaclass(metaclass(cls)))
	assert(isclass(cls))
	assert(not ismetaclass(cls))
	assert(not isobj(cls))
	assert(isclass(metaclass(cls)))

	local obj = cls:new()
	assert(isobj(obj))
	assert(not isclass(obj))
end

function test.refcount()
	local cls = class(genname(), 'NSObject')
	local inst, inst2, inst3

	inst = cls:new()
	assert(inst:retainCount() == 1)

	inst2 = inst:retain() --same class, new cdata, new reference
	assert(inst:retainCount() == 2)

	inst3 = inst:retain()
	assert(inst:retainCount() == 3)

	inst3 = nil --release() on gc
	collectgarbage()
	assert(inst:retainCount() == 2)

	inst3 = inst:retain()
	assert(inst:retainCount() == 3)

	inst:release() --manual release()
	assert(inst:retainCount() == 2)

	inst = nil --object already disowned by inst, refcount should not decrease
	collectgarbage()
	assert(inst2:retainCount() == 2)

	inst, inst2, inst3 = nil
	collectgarbage()
end

function test.luavars()
	local cls = class(genname(), 'NSObject')

	--class vars
	cls.myclassvar = 'doh1'
	assert(cls.myclassvar == 'doh1') --intialized
	cls.myclassvar = 'doh'
	assert(cls.myclassvar == 'doh') --updated

	--inst vars
	local inst = cls:new()

	inst.myinstvar = 'DOH1'
	assert(inst.myinstvar == 'DOH1') --initialized
	inst.myinstvar = 'DOH'
	assert(inst.myinstvar == 'DOH') --updated

	--class vars from instances
	assert(inst.myclassvar == 'doh') --class vars are readable from instances
	inst.myclassvar = 'doh2'
	assert(cls.myclassvar == 'doh2') --and they can be updated from instances
	assert(inst.myclassvar == 'doh2')

	--soft ref counting
	local inst2 = inst:retain()
	assert(inst.myinstvar == 'DOH') --2 refs
	inst = nil
	collectgarbage()
	assert(inst2.myinstvar == 'DOH') --1 ref
	inst2:release() --0 refs; instance gone, vars gone (no way to test, memory was freed)
	assert(cls.myclassvar == 'doh2') --class vars still there

	local i = 0
	function NSObject:myMethod() i = i + 1 end
	local str = toobj'hello'   --create a NSString instance, which is a NSObject
	str:myMethod()             --instance method (str passed as self)
	objc.NSString:myMethod()   --class method (NSString passed as self)
	assert(i == 2)

	function NSObject:myMethod() i = i - 1 end --override
	str:myMethod()             --instance method (str passed as self)
	objc.NSString:myMethod()   --class method (NSString passed as self)
	assert(i == 0)
end

function test.override()
	objc.debug.logtopics.addmethod = true

	local cls = class(genname(), 'NSObject')
	local metacls = metaclass(cls)
	local obj = cls:new()
	local instdesc = 'hello-instance'
	local classdesc = 'hello-class'

	function metacls:description() --override the class method
		return classdesc --note: we can return the string directly.
	end

	function cls:description() --override the instance method
		return instdesc --note: we can return the string directly.
	end

	assert(objc.tolua(cls:description()) == classdesc) --class method was overriden
	assert(objc.tolua(obj:description()) == instdesc) --instance method was overriden and it's different

	--subclass and test again

	local cls2 = class(genname(), cls)
	local metacls2 = metaclass(cls2)
	local obj2 = cls2:new()

	function metacls2:description() --override the class method
		return objc.callsuper(self, 'description'):UTF8String() .. '2'
	end

	function cls2:description(callsuper) --override the instance method
		return objc.callsuper(self, 'description'):UTF8String() .. '2'
	end

	assert(objc.tolua(cls2:description()) == classdesc..'2') --class method was overriden
	assert(objc.tolua(obj2:description()) == instdesc..'2') --instance method was overriden and it's different
end

function test.ivars()
	local obj = NSDocInfo:new()

	if ffi.abi'64bit' then
		assert(ffi.typeof(obj.time) == ffi.typeof'long long')
	else
		assert(type(obj.time) == 'number')
	end
	assert(type(obj.mode) == 'number') --unsigned short
	assert(ffi.typeof(obj.flags) == ffi.typeof(obj.flags)) --anonymous struct (assert that it was cached)

	obj.time = 123
	assert(obj.time == 123)

	assert(obj.flags.isDir == 0)
	obj.flags.isDir = 3 --1 bit
	assert(obj.flags.isDir == 1) --1 bit was set (so this is not a luavar or anything)
end

function test.properties()
	--TODO: find another class with r/w properties. NSProgress is not public on 10.7.
	local pr = NSProgress:progressWithTotalUnitCount(123)
	assert(pr.totalUnitCount == 123) --as initialized
	pr.totalUnitCount = 321 --read/write property
	assert(pr.totalUnitCount == 321)
	assert(not pcall(function() pr.indeterminate = true end)) --attempt to set read-only property
	assert(pr.indeterminate == false)
end

local timebase, last_time
function timediff()
	objc.load'System'
	local time
	time = mach_absolute_time()
	if not timebase then
		timebase = ffi.new'mach_timebase_info_data_t'
		mach_timebase_info(timebase)
	end
	local d = tonumber(time - (last_time or 0)) * timebase.numer / timebase.denom / 10^9
	last_time = time
	return d
end

function test.blocks()
	--objc.debug.logtopics.block = true
	local times = 20000

	timediff()

	--take 1: creating blocks in inner loops with automatic memory management of blocks.
	local s = NSString:alloc():initWithUTF8String'line1\nline2\nline3'
	for i=1,times do
		local t = {}
		--note: the signature of the block arg for enumerateLinesUsingBlock was taken from bridgesupport.
		s:enumerateLinesUsingBlock(function(line, pstop)
			t[#t+1] = line:UTF8String()
			if #t == 2 then --stop at line 2
				pstop[0] = 1
			end
		end)
		assert(#t == 2)
		assert(t[1] == 'line1')
		assert(t[2] == 'line2')
		--note: callbacks are slow, expensive to create, and limited in number. we have to release them often!
		if i % 200 == 0 then
			collectgarbage()
		end
	end

	printf('take 1: block in loop (%d times): %4.2fs', times, timediff())

	--take 2: creating a single block in the outer loop (we must give its type).
	local t
	local blk = toarg(NSString, 'enumerateLinesUsingBlock', 1, function(line, pstop)
			t[#t+1] = line:UTF8String()
			if #t == 2 then --stop at line 2
				pstop[0] = 1
			end
	end)
	local s = NSString:alloc():initWithUTF8String'line1\nline2\nline3'
	for i=1,times do
		t = {}
		s:enumerateLinesUsingBlock(blk)
		assert(#t == 2)
		assert(t[1] == 'line1')
		assert(t[2] == 'line2')
	end

	printf('take 2: single block  (%d times): %4.2fs', times, timediff())

end

function test.tolua()
	local n = toobj(123.5)
	assert(isa(n, 'NSNumber'))
	assert(tolua(n) == 123.5)

	local s = toobj'hello'
	assert(isa(s, 'NSString'))
	assert(tolua(s) == 'hello')

	local a = {1,2,6,7}
	local t = toobj(a)
	assert(t:count() == #a)
	for i=1,#a do
		assert(t:objectAtIndex(i-1):doubleValue() == a[i])
	end
	a = tolua(t)
	assert(#a == 4)
	assert(a[3] == 6)

	local d = {a = 1, b = 'baz', d = {1,2,3}, [{x=1}] = {y=2}}
	local t = toobj(d)
	assert(t:count() == 4)
	assert(tolua(t:valueForKey(toobj'a')) == d.a)
	assert(tolua(t:valueForKey(toobj'b')) == d.b)
	assert(tolua(t:valueForKey(toobj'd'))[2] == 2)
end

function test.args()
	local s = NSString:alloc():initWithUTF8String'\xE2\x82\xAC' --euro symbol
	--return string
	assert(s:UTF8String() == '\xE2\x82\xAC')
	--return boolean (doesn't work for methods)
	assert(s:isAbsolutePath() == false)
	--return null
	assert(type(s:cStringUsingEncoding(NSASCIIStringEncoding)) == 'nil')
	--selector arg
	assert(s:respondsToSelector'methodForSelector:' == true)
	--class arg
	assert(NSArray:isSubclassOfClass'NSObject' == true)
	assert(NSArray:isSubclassOfClass'XXX' == false)
	--string arg
	assert(NSString:alloc():initWithString('hey'):UTF8String() == 'hey')
	--table arg for array
	local a = NSArray:alloc():initWithArray{6,25,5}
	assert(a:objectAtIndex(1):doubleValue() == 25)
	--table arg for dictionary
	local d = NSDictionary:alloc():initWithDictionary{a=5,b=7}
	assert(d:valueForKey('b'):doubleValue() == 7)
end

function demo.window()
	objc.load'AppKit'

	local NSApp = class('NSApp', 'NSApplication <NSApplicationDelegate>')

	--we need to add methods to the class before creating any objects!
	--note: NSApplicationDelegate is an informal protocol brought from bridgesupport.

	function NSApp:applicationShouldTerminateAfterLastWindowClosed()
		print'last window closed...'
		collectgarbage()
		return true
	end

	function NSApp:applicationShouldTerminate()
		print'terminating...'
		return true
	end

	local app = NSApp:sharedApplication()
	app:setDelegate(app)
	app:setActivationPolicy(NSApplicationActivationPolicyRegular)

	local NSWin = class('NSWin', 'NSWindow <NSWindowDelegate>')

	--we need to add methods to the class before creating any objects!
	--note: NSWindowDelegate is a formal protocol brought from the runtime.

	function NSWin:windowWillClose()
		print'window will close...'
	end

	local style = bit.bor(
						NSTitledWindowMask,
						NSClosableWindowMask,
						NSMiniaturizableWindowMask,
						NSResizableWindowMask)

	local win = NSWin:alloc():initWithContentRect_styleMask_backing_defer(
						NSMakeRect(300, 300, 500, 300), style, NSBackingStoreBuffered, false)
	win:setDelegate(win)
	win:setTitle"▀▄▀▄▀▄ [ Lua Rulez ] ▄▀▄▀▄▀"

	app:activateIgnoringOtherApps(true)
	win:makeKeyAndOrderFront(nil)

	app:run()
end

function demo.speech()
	objc.load'AppKit'
	local speech = NSSpeechSynthesizer:new()
	voiceid = NSSpeechSynthesizer:availableVoices():objectAtIndex(11)
	speech:setVoice(voiceid)
	speech:startSpeakingString'Calm, fitter, healthier, and more productive; A pig. In a cage. On antibiotics.'
	while speech:isSpeaking() do
		os.execute'sleep 1'
	end
end

function demo.http() --what a dense word soup just to make a http request
	objc.load'AppKit'
	local app = NSApplication:sharedApplication()

	local post = NSString:stringWithFormat('firstName=%@&lastName=%@&eMail=%@&message=%@',
						toobj'Dude', toobj'Edud', toobj'x@y.com', toobj'message')
	local postData = post:dataUsingEncoding(NSUTF8StringEncoding)
	local postLength = NSString:stringWithFormat('%ld', postData:length())

	NSLog('Post data: %@', post)

	local request = NSMutableURLRequest:new()
	request:setURL(NSURL:URLWithString'http://posttestserver.com/post.php')
	request:setHTTPMethod'POST'
	request:setValue_forHTTPHeaderField(postLength, 'Content-Length')
	request:setValue_forHTTPHeaderField('application/x-www-form-urlencoded', 'Content-Type')
	request:setHTTPBody(postData)

	NSLog('%@', request)

	local CD = class('ConnDelegate', 'NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate>')

	function CD:connection_didReceiveData(conn, data)
		self.webData:appendData(data)
		NSLog'Connection received data'
	end

	function CD:connection_didReceiveResponse(conn, response)
		NSLog'Connection received response'
		NSLog('%@', response:description())
	end

	function CD:connection_didFailWithError(conn, err)
		NSLog('Connection error: %@', err:localizedDescription())
		app:terminate(nil)
	end

	function CD:connectionDidFinishLoading(conn)
		NSLog'Connection finished loading'
		local html = NSString:alloc():initWithBytes_length_encoding(self.webData:mutableBytes(),
																self.webData:length(), NSUTF8StringEncoding)
		NSLog('OUTPUT:\n%@', html)
		app:terminate(nil)
	end

	local cd = ConnDelegate:new()
	cd.webData = NSMutableData:new()

	local conn = NSURLConnection:alloc():initWithRequest_delegate_startImmediately(request, cd, false)
	conn:start()

	app:run()
end

function demo.http_gcd()
	objc.load'AppKit'
	local app = NSApplication:sharedApplication()

	local url = NSURL:URLWithString'http://posttestserver.com/post.php'
	local req = NSURLRequest:requestWithURL(url)

	local queue = dispatch.main_queue --dispatch.get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

	objc.debug.logtopics.block = true

	local n = 0
	local blk = block(function()
		n = n + 1
		print('called', n)

		local response = ffi.new'id[1]'
		local err = ffi.new'id[1]'
		local data = NSURLConnection:sendSynchronousRequest_returningResponse_error(req, response, err)

		print(tolua(NSString:alloc():initWithBytes_length_encoding(
						data:mutableBytes(), data:length(), NSUTF8StringEncoding)))

		if n == 2 then
			print'---- Done. Hit Ctrl+C twice ----'
		end
	end)
	dispatch.async(queue, blk)  --increase refcount
	dispatch.async(queue, blk)  --increase refcount
	print'queued'
	blk = nil; collectgarbage() --decrease refcount (stil queued)
	print'released'
	app:run()
end

-- inspection ------------------------------------------------------------------------------------------------------------

local function load_many_frameworks()
	objc.debug.loaddeps = true
	for s in string.gmatch([[
AGL
AVFoundation
AVKit
Accelerate
Accounts
AddressBook
AppKit
AppKitScripting
AppleScriptKit
AppleScriptObjC
AppleShareClientCore
ApplicationServices
AudioToolbox
AudioUnit
AudioVideoBridging
Automator
CFNetwork
CalendarStore
Carbon
Cocoa
Collaboration
CoreAudio
CoreAudioKit
CoreData
CoreFoundation
CoreGraphics
CoreLocation
CoreMIDI
CoreMedia
CoreMediaIO
CoreServices
CoreText
CoreVideo
CoreWLAN
DVComponentGlue
DVDPlayback
DirectoryService
DiscRecording
DiscRecordingUI
DiskArbitration
DrawSprocket
EventKit
ExceptionHandling
FWAUserLib
ForceFeedback
Foundation
GLKit
GLUT
GSS
GameController
GameKit
ICADevices
IMServicePlugIn
IOBluetooth
IOBluetoothUI
IOKit
IOSurface
ImageCaptureCore
ImageIO
InputMethodKit
InstallerPlugins
InstantMessage
JavaFrameEmbedding
JavaScriptCore
Kerberos
LDAP
LatentSemanticMapping
MapKit
MediaAccessibility
MediaLibrary
MediaToolbox
NetFS
OSAKit
OpenAL
OpenCL
OpenDirectory
OpenGL
PCSC
PreferencePanes
PubSub
QTKit
Quartz
QuartzCore
QuickLook
SceneKit
ScreenSaver
Scripting
ScriptingBridge
Security
SecurityFoundation
SecurityInterface
ServiceManagement
Social
SpriteKit
StoreKit
SyncServices
System
SystemConfiguration
TWAIN
Tcl
Tk
VideoDecodeAcceleration
VideoToolbox
WebKit
]], '([^\n\r]+)') do
		pcall(objc.load, s)
	end
	objc.debug.loaddeps = false
end

function eyetest.inspect_classes()
	load_many_frameworks()
	inspect.classes()
end

function eyetest.inspect_protocols()
	load_many_frameworks()
	inspect.protocols()
end

function eyetest.inspect_class_properties(cls)
	load_many_frameworks()
	inspect.class_properties(cls)
end

function eyetest.inspect_protocol_properties(proto)
	load_many_frameworks()
	inspect.protocol_properties(proto)
end

local function req(s)
	return s and s ~= '' and s or nil
end

function eyetest.inspect_class_methods(cls, inst)
	load_many_frameworks()
	inspect.class_methods(req(cls), inst == 'inst')
end

function eyetest.inspect_protocol_methods(proto, inst, required)
	load_many_frameworks()
	inspect.protocol_methods(req(proto), inst == 'inst', required == 'required')
end

function eyetest.inspect_class_ivars(cls)
	load_many_frameworks()
	inspect.class_ivars(req(cls))
end

function eyetest.inspect_class(cls)
	load_many_frameworks()
	inspect.class(cls)
end

function eyetest.inspect_protocol(proto)
	load_many_frameworks()
	inspect.protocol(proto)
end

function eyetest.inspect_find(patt)
	load_many_frameworks()
	inspect.find(patt)
end

--------------

local function test_all(tests, ...)
	for k,v in glue.sortedpairs(tests) do
		if k ~= 'all' then
			print(k)
			hr()
			tests[k](...)
		end
	end
end

function test.all(...)
	test_all(test)
end

--cmdline interface

local function run(...)
	local testname = ...
	if not testname then
		print('Usage: '..luajit..' '..arg[0]..' <test>')
		for k,t in glue.sortedpairs(tests) do
			printf('%s:', k)
			for k in glue.sortedpairs(t) do
				print('', k)
			end
		end
	else
		local test = test[testname] or eyetest[testname] or demo[testname]
		if not test then
			printf('Invalid test "%s"', tostring(testname))
			os.exit(1)
		end
		test(select(2, ...))
		print'ok'
	end
end

run(...)
