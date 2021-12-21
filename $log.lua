 --[[

	$ | logging and error checking.

	log(severity, module, event, fmt, ...)
	note(module, event, fmt, ...)
	dbg(module, event, fmt, ...)
	warnif(module, event, condition, fmt, ...)
	logerror(module, event, fmt, ...)

	logargs(...) -> ...
	logprintargs(...) -> ...

	logging.env <- 'dev' | 'prod', etc.
	logging.filter <- {severity->true}

	logging:tofile(logfile, max_disk_size)
	logging:toserver(host, port, queue_size, timeout)

]]

require'$'
logging = require'logging'

log      = logging.log
note     = logging.note
dbg      = logging.dbg
warnif   = logging.warnif
logerror = logging.logerror
logargs  = logging.args
logprintargs = logging.printargs

function pr(...)
	print(logprintargs(...))
	io.stdout:flush()
	return ...
end
