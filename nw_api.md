---
tagline:   native widgets API
---

## `local nw = require'nw'`

> In the following table "?" means boolean.

-----------------------------------------------------------------------------------------------------------------
__topic__			__actions__								__queries__									__events__
----------------- -------------------------------- ----------------------------------- --------------------------
app object														nw:app() -> app

message loop		app:run() \								app:running()
						app:stop()

quitting				app:autoquit(t|f) \					app:autoquit() -> t|f \					\
						win:autoquit(t|f) \					win:autoquit() -> t|f					\
						app:quit()																				`app:quitting() -> [refuse]`

timers				app:runevery(seconds, func) \														func() -> continue?
						app:runafter(seconds, func)

window list														app:windows([order]) -> {win1,...}\	app:window_created() \
																	app:window_count() -> n  				app:window_closed()

windows				app:window(t) -> win \				\												\
						win:close() 							win:dead() -> t|f							win:closing() -> t|f \
																													win:closed()

app activation		app:activate()	\						app:active() -> t|f \					app:activated() \
																													app:deactivated()

window activation	win:activate()							win:active() -> t|f \					win:activated() \
																	app:active_window() -> win				win:deactivated()

window state		win:show() \							win:visible() -> t|f \					win:was_shown() \
						win:hide() \							\												win:was_hidden() \
						win:minimize() \						win:minimized() -> t|f \				win:was_minimized() \
						win:maximize() \						win:maximized() -> t|f \				win:was_maximized() \
						win:restore() \						\												win:was_unminimized() \
						win:shownormal() \					\												win:was_unmaximized() \
						win:fullscreen()						win:fullscreen() -> t|f					win:entered_fullscreen() \
																													win:exited_fullscreen()

position				win:frame_rect(x, y, w, h)			win:frame_rect() -> x, y, w, h \		win:resizing(how, x, y, w, h) -> x, y, w, h \
																	win:client_rect() -> x, y, w, h		win:was_resized(w, h) \
																													win:was_moved(x, y)

displays															app:displays() -> {disp1, ...} \		app:displays_changed()
																	app:display_count() -> n \
																	app:active_display() -> disp \
																	win:display() -> disp \
																	disp:rect() -> x, y, w, h \
																	disp:client_rect() -> x, y, w, h

mouse pointer		win:cursor(name)

frame					win:title(title) \					win:title() -> title \
						\											win:frame() -> frame \
						\											win:minimizable() -> t|f \
						\											win:maximizable() -> t|f \
						\											win:closeable() -> t|f \
						\											win:resizeable() -> t|f \
						\											win:fullscreenable() -> t|f \
						win:edgesnapping(?)					win:edgesnapping() -> t|f

z-order				win:topmost(?) \						win:topmost() -> t|f \
						win:order(z|'back'|'front')		win:zorder() -> z

parent															win:parent() -> parent

keyboard				app:ignore_numlock(t|f)				app:ignore_numlock() -> t|f \			win:keydown(key, vkey) \
																	win:key(keyquery) -> t|f				win:keyup(key, vkey) \
																													win:keypress(key, vkey) \
																													win:keychar(char)

mouse																win:mouse() -> m \						win:mousedown(button) \
																	m.x, m.y, \									win:click(button, count) -> t|f \
																	m.left, m.right, m.middle, \			win:mouseup(button) \
																	m.ex1, m.ex2 \								win:mouseenter() \
																	win:mouse(var) -> m[var]				win:mouseleave() \
																													win:mousemove(x, y) \
																													win:mousewheel(delta) \
																													win:mousehwheel(delta)

rendering			win:invalidate()																		win:render(cr)

menus					app:menu() -> menu \					win:menubar() -> menu \
						menu:add([i,]text,action) -> i \	\
						menu:add([i,]text,menu) -> i \	\
						menu:add(args) -> i \				\
						menu:set(index, text, action) \	menu:get(index) -> {text=,...} \
						menu:set(index, text, menu) \		\
						menu:set(menuitem) \					menu:get(index) -> menuitem \
						\											menu:item_count() -> n \
						menu:checked(index, t|f) \			menu:checked(index) -> ? \
						menu:enabled(index, t|f)			menu:enabled(index) -> ?

backends				nw:init([backendname]) 				nw.backends-> {OS = backendname} \
																	nw.backend.name -> name \
																	nw:os() -> os_version \
																	nw:os(compat_version) -> ?

events				obj:on(event, func		) 															obj:event(name, args...) \
																													obj:\<eventname\>(args...)
-----------------------------------------------------------------------------------------------------------------
