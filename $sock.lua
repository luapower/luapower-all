--[[

	$ | networking

]]

require'$'
sock = require'sock'

newthread      = sock.newthread
thread         = sock.thread
resume         = sock.resume
suspend        = sock.suspend
transfer       = sock.transfer
cowrap         = sock.cowrap
yield          = sock.yield
currentthread  = sock.currentthread
onthreadfinish = sock.onthreadfinish
sleep_until    = sock.sleep_until
sleep          = sock.sleep
sleep_job      = sock.sleep_job
runat          = sock.runat
runafter       = sock.runafter
runevery       = sock.runevery
