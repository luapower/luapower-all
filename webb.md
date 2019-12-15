---
tagline: Procedural web framework for OpenResty
requires: nginx
---

## Status

<warn>In active development.</warn>

## HowTO

Here's a very basic website sketch that uses some webb features.

Create a file `foo-nginx.conf` and type in it:

```
error_log logs/foo-error.log;  # default is logs/error.log.
events {}
http {
	lua_code_cache off;           # auto-reload Lua modules (for development).
	server {
		listen 127.0.0.1:8000;     # default is *:8000;
		set $main_module "foo";    # runs foo.lua for every url.
		set $hide_errors true;     # hide errors when crashing (for production).
		access_log logs/foo-access.log;  # default is logs/access.log.
		include webb-nginx.conf;   # hook up webb to nginx.
	}
}
```

Type `./nginx -s start` then check `http://127.0.0.1:8000`.

You should get a 500 error because `foo.lua` (our main file) is missing.
Below is an example on how to set up this file.

### `foo.lua`

```
require'webb'           -- base API.
require'webb_js'        -- support API for www/webb.js.
require'webb_query'     -- if using mysql.
require'webb_sendmail'  -- if sending mail.
require'webb_session'   -- if needing session tracking and/or user accounts.
require'webb_session'   -- if needing session tracking and/or user accounts.
require'foo_config'     -- foo_config.lua file, see below.
require'foo_secrets'    -- foo_secrets.lua file, see below.

cssfile[[
	font-awesome.css    --if using font awesome
	jquery.toasty.css   --if using toasty
]]

jsfile[[
	jquery.toasty.js    --if using toasty notifications
	jquery.easing.js    --if using easing transitions
	jquery.validate.js  --if using client-side validation
	jquery.unslider.js  --if using unslider
	analytics.js        --if using analytics
	facebook.js         --if using facebook authentication
	google.js           --if using g+ authentication
	account.js          --if using the standard account widget TODO
	resetpass.js        --if using the sandard reset password widget TODO
	config.js           --auto-generated with some values from foo_config.lua
]]

function action.home()
	webbjs {
		title = '...',
		body = '...',
	}
end

return function()  --called for every URL. make your routing strategy here.
	touch_usr() --update usr.atime on all requests, except image requests.
	check(action(find_action(unpack(args()))))
end
```

### `foo_config.lua`

Note: only need to add the lines for which the value is different than below.
Also note: these can also be set as nginx variables (`set` directive) or as
environment variables.

```
config('lang', 'en') --the default language

config('base_url', nil)   --website's base url: optional, for absurl().

config('root_action'      , 'home') --the action to run for the '/' path
config('templates_action' , '_templates')
config('404_html_action'  , '404.html')
config('404_png_action'   , '404.png')
config('404_jpeg_action'  , '404.jpg')

config('separate_js_refs' , false) --concatenate all js files into all.js
config('separate_css_refs', false) --concatenate all css files into all.css

config('db_host', '127.0.0.1')    --the ip address of the local mysql server
config('db_port', 3306)           --the port of the local mysql server
config('db_name', '<db name>')    --the mysql database name
config('db_user', 'root')         --the mysql user
config('db_conn_timeout' , 3)     --connection timeout in seconds
config('db_query_timeout', 30)    --query timeout in seconds

config('pass_token_lifetime', 3600) --remember-password token lifetime
config('pass_token_maxcount', 2)  --max remember-password tokens allowed

config('smtp_host', '127.0.0.1')  --the ip address of the local smtp server
config('smtp_port', 25)           --the port address of the local smtp server

config('facebook_app_id',  '<fb app id>')         --fb app id for fb authentication
config('google_client_id', '<google client id>')  --google client id for g+ authentication
config('analytics_ua',     '<analytics UA code>') --google analytics UA code for analytics
```

### `foo_secrets.lua`, not to be added to git

```
config('pass_salt',      '<any random string>') --for encrypting passwords in the database
config('session_secret', '<any random string>') --for encrypting cookies
config('db_pass',        nil)                   --the mysql password
```

## Webb modules

------------------------------ -----------------------------------------------
webb.lua                       main module
webb_action.lua                routing module
webb_query.lua                 mysql query module
webb_sendmail.lua              email sending
webb_js.lua                    webb.js support module
webb_session.lua               cookie-based sessions
webb_auth.lua                  session authentication
www/webb.js                    client-side main module
www/webb.ajax.js               ajax module
www/webb.timeago.js            time formatting
www/webb.util.js               misc.
www/webb.back-to-top.js        back-to-top button
www/webb.content-tools.js      contenteditable library
------------------------------ -----------------------------------------------

## Third-party modules

----------------------- ------ -----------------------------------------------
resty/socket.lua        0.0.4  thibaultcha/lua-resty-socket
webb_mysql.lua          ?      lua-resty-mysql; db:read_result() modified for query.lua!
lp.lua                  1.15
www/jquery.js           3.4.1
www/jquery.history.js   1.8.0
www/jquery.validate.js  1.19.1
www/jquery.easing.js    1.3
www/jquery.toasty.js    ?
www/jwuery.unslider.js  ?
www/mustache.js         3.1.0
www/normalize.css       8.0.1
----------------------- ------ -----------------------------------------------

### Reset MySQL root password

```
sudo mysql -u root

DROP USER 'root'@'localhost';
CREATE USER 'root'@'%' IDENTIFIED BY '';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%';
FLUSH PRIVILEGES;
```
