---
tagline: procedural web framework for OpenResty
---

Webb is a procedural web framework for [openresty].

## HowTO

Here's a very basic website sketch that uses some webb features.

Create a file `nginx-server-foo.conf` and type in it:

```
server {
	listen 127.0.0.1:8000;     # default is *:8000;
	set $main_module "main";   # runs main.lua for every url.
	set $hide_errors true;     # hide errors when crashing (for production).
	include nginx-webb.conf;   # hook up webb to nginx.
}
```

Type `./nginx -s start` then check `http://127.0.0.1:8000`.

You should get a 500 error because `main.lua` (our main file) is missing.
Below is an example on how to set up this file.

### `main.lua`

```
require'webb'      -- base webb API, see webb.lua.
require'webbjs'    -- webbjs support API, see www/webb.js and webbjs.lua.
require'query'     -- if using mysql.
require'sendmail'  -- if sending mail.
require'session'   -- if needing session tracking and/or user accounts.
require'config'    -- config.lua file, see below.
require'secrets'   -- secrets.lua file, see below.

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
	config.js           --auto-generated with some values from config.lua
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

### `config.lua`

Note: only need to add the lines for which the value is different than below.
Also note: these can also be set as environment variables as well as nginx
variables (`set` directive).

```
config('lang', 'en') --the default language

config('base_url', nil)   --website's base url: optional, for absurl().
config('www_dir' , 'www') --the static files dir, relative to luapower's dir.

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

### `secrets.lua`, not to be added to git

```
config('pass_salt',      '<any random string>') --for encrypting passwords in the database
config('session_secret', '<any random string>') --for encrypting cookies
config('db_pass',        nil)                   --the mysql password
```

## Webb modules

------------------------------ -----------------------------------------------
webb.lua                       main module
action.lua                     routing module
query.lua                      mysql query module
session.lua                    session and authentication module
sendmail.lua                   sending emails
webbjs.lua                     webb.js support module
www/webb.js                    client-side main module
www/webb.ajax.js               ajax module
www/webb.timeago.js            time formatting
www/webb.util.js               misc.
www/webb.back-to-top.js        back-to-top button
www/webb.content-tools.js      contenteditable library
------------------------------ -----------------------------------------------

## Third-party modules

----------------------- ------ -----------------------------------------------
resty/session.lua       1.1    bungle/lua-resty-session
resty/socket.lua        0.0.4  thibaultcha/lua-resty-socket
resty/mysql.lua         ?      built-in, db:read_result() modified for query.lua!
lp.lua                  1.15
jquery.js               3.4.1
jquery.history.js       1.8.0
jquery.validate.js      1.19.1
jquery.easing.js        1.3
mustache.js             3.1.0
normalize.css           8.0.1
----------------------- ------ -----------------------------------------------

### Reset MySQL root password

```
sudo mysql -u root

DROP USER 'root'@'localhost';
CREATE USER 'root'@'%' IDENTIFIED BY '';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%';
FLUSH PRIVILEGES;
```
