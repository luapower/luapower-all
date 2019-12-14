--[==[

	webb | webb.js support module
	Written by Cosmin Apreutesei. Public Domain.

CONFIG

	config('page_title_suffix')         suffix for <title>
	config('separate_js_refs', false)   separate <script> refs or all.js
	config('separate_css_refs', false)  separate <link> refs or all.css

API

	cssfile(file)                       add one or more css files to all.css
	jsfile(file)                        add one or more js files to all.js
	css(s)                              add css code to inline.css
	js(s)                               add js code to inline.js

	page_title([title], [body]) -> s    set/infer page title

	webbjs(t)                           webbjs html action
		t.head: s                        content for <head>
		t.body: s                        content for <body>
		t.title: s                       content for <title> (optional)
		t.client_action: t|f             should run client-side action or not


INTERNAL API

	action['config.js']                 expose required config() values
	action['strings.js']                load strings.<lang>.js
	action['all.js']                    output of jsfile() calls
	action['all.css']                   output of cssfile() calls
	action['inline.js']                 output of js() calls
	action['inline.css']                output of css() calls
	action.__templates                  for load_templates()

	config'templates_action'            for load_templates()
	config'aliases'                     for lang_url() and find_action()
	config'page_title_suffix'           for pagetitle()

	config'facebook_app_id'             for webb.auth.facebook.js
	config'google_client_id'            for webb.auth.google.js
	config'analytics_ua'                for webb.analytics.js

LOADS

	normalize.css

	jquery.js
	jquery.history.js
	mustache.js
	webb.js
	webb.ajax.js
	webb.timeago.js
	webb.util.js
	webb.analytics.js

]==]

require'webb'
require'webb_action'

--pass required config values to the client
action['config.js'] = function()

	local cjson = require'cjson'

	--initialize some required config values with defaults.
	config('lang', 'en')
	config('root_action', 'en')
	config('templates_action', '__templates')
	config('page_title_suffix', ' - '..host())

	local function C(name)
		if config(name) == nil then return end
		out('config('
			..cjson.encode(name)..', '
			..cjson.encode(config(name))..')\n')
	end

	C'lang'
	C'aliases'
	C'root_action'
	C'templates_action'
	C'page_title_suffix'

	C'facebook_app_id'
	C'analytics_ua'
	C'google_client_id'

end

--make render() work on the client-side
function action.__templates()
	for _,name in ipairs(template()) do
		out(mustache_wrap(template(name), name))
	end
end

--organize string translations in separate files for each langauge
action['strings.js'] = function()
	if lang() == 'en' then return end
	action('strings.'..lang()..'.js')
end

--simple API to add js and css snippets and files from server-side code

local function sepbuffer(sep)
	local buf = stringbuffer()
	return function(s)
		if s then
			buf(s)
			buf(sep)
		else
			return buf()
		end
	end
end

cssfile = sepbuffer'\n'
readfile['all.css.cat'] = function()
	return cssfile() .. ' inline.css' --append inline code at the end
end

jsfile = sepbuffer'\n'
readfile['all.js.cat'] = function()
	return jsfile() .. ' inline.js' --append inline code at the end
end

css = sepbuffer'\n'
readfile['inline.css'] = function()
	return css()
end

js = sepbuffer';\n'
readfile['inline.js'] = function()
	return js()
end

cssfile[[
normalize.css
]]

jsfile[[
jquery.js
jquery.history.js  // for exec() and ^url_changed
mustache.js        // for render()

webb.js
webb.ajax.js
webb.timeago.js
webb.util.js
webb.analytics.js

config.js          // dynamic config
strings.js         // strings in current language
]]

--format js and css refs as separate refs or as a single ref based on a .cat action

function jslist(cataction, separate)
	if not separate then
		return string.format('	<script src="%s" async></script>', lang_url('/'..cataction))
	end
	local out = stringbuffer()
	for i,file in ipairs(catlist_files(readfile(cataction..'.cat'))) do
		out(string.format('	<script src="%s"></script>\n', lang_url('/'..file)))
	end
	return out()
end

function csslist(cataction, separate)
	if not separate then
		return string.format('	<link rel="stylesheet" type="text/css" href="/%s">', cataction)
	end
	local out = stringbuffer()
	for i,file in ipairs(catlist_files(readfile(cataction..'.cat'))) do
		out(string.format('	<link rel="stylesheet" type="text/css" href="/%s">\n', file))
	end
	return out()
end

--main template gluing it all together

local webbjs_template = [[
<!DOCTYPE html>
<html lang="{{lang}}">
<head>
	<meta charset="UTF-8">
	<title>{{title}}{{title_suffix}}</title>
{{{all_js}}}
{{{all_css}}}
{{{head}}}
	<script>
		$(function() {
			analytics_init()
			load_templates(function() {
				$(document).setup()
				{{#client_action}}
					url_changed()
				{{/client_action}}
			})
		})
	</{{undefined}}script>
</head>
<body>
	<div style="display: none;" id="__templates"></div>
{{{body}}}
</body>
</html>
]]

function page_title(title, body)
	return title
		--infer it from the top heading
		or (body and body:match'<h1[^>]*>(.-)</h1>')
		--infer it from the name of the action
		or args(1):gsub('[-_]', ' ')
end

function webbjs(p)
	local t = {}
	t.lang = lang()
	t.body = filter_lang(p.body, lang())
	t.head = p.head
	t.title = page_title(p.title, t.body)
	t.title_suffix = config('page_title_suffix', ' - '..host())
	t.client_action = p.client_action
	t.all_js = jslist('all.js', config('separate_js_refs', false))
	t.all_css = csslist('all.css', config('separate_css_refs', false))
	out(render_string(webbjs_template, t))
end
