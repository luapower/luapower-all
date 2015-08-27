--codedit: code editor engine (Cosmin Apreutesei, public domain).
local editor = require'codedit_editor'
--require'codedit_metrics'
--require'codedit_scroll'
--require'codedit_render'
require'codedit_keys'
require'codedit_ui'

if not ... then require'codedit_demo' end

return editor
