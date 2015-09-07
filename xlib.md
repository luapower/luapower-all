---
tagline: libX11 binding
platforms: linux32, linux64
---

## `local xlib = require'xlib'`

Binding of libX11 library and higher-level cruft-hiding API.
Created mainly for [nw]'s [xlib backend], but directly usable for X11-only apps.

[xlib backend]: https://github.com/luapower/nw/blob/master/nw_xlib.lua

## API

--------------------------------------------------- -----------------------------------------------
__connection__
`xlib_module.connect([displayname]) -> xlib`        connect and get a xlib API for that connection
`xlib.flush()`                                      flush the command queue
`xlib.screen`                                       default screen
__server__
`xlib.extension_map() -> {name = true}`             get available X extensions
`xlib.extension(name) -> true|false`                check if an extension is available
__events__
`xlib.poll([block]) -> event | nil`                 poll (or wait) for the next event
`xlib.peek() -> event | nil`                        get the next event without pulling it
__atoms__
`xlib.atom(name) -> atom`                           intern an atom
`xlib.atom_name(atom) -> s | nil`                   get an atom's name
__screens__
`xlib.screens() -> iter() -> screen_num, screen`    iterate screens
__constructors and destructors__
`xlib.create_window(...)`                           XCreateWindow wrapper
`xlib.destroy_window(win)`                          XDestroyWindow wrapper
`xlib.create_colormap(...)`                         XCreateColormap wrapper
__window properties__
`xlib.list_props(win) -> {name1, ...}`              list properties
`xlib.delete_prop(win, prop)`                       delete a property
`xlib.get_string_prop(win, prop) -> s`              get a string-type property
`xlib.set_string_prop(win, prop, s)`                set a string-type property
`xlib.get_atom_map_prop(win, prop) -> t`            get an atom map-type property
`xlib.set_atom_map_prop(win, prop, t)`              set an atom map-type property
`xlib.set_atom_prop(win, prop, val)`                set an atom-type property
`xlib.set_cardinal_prop(win, prop, n)`              set an integer-type property
`xlib.get_window_prop(win, prop) -> win`            get a window-type property
`xlib.set_window_prop(win, prop, target_win)`       set a window-type property
`xlib.get_window_list_prop(win, prop) -> t`         get a window list-type property
__client message events__
`client_message_event(win, type, fmt) -> e`         create a client message event
`int32_list_event(win, type, n1, ...) -> e`         create an integer list event
`atom_list_event(win, type, atom1, ...) -> e`       create an atom list event
`send_client_message_to_root(e)`                    send a client message to screen.root
__window management__
`xlib.get_geometry(win) -> geom`                    get window geometry as xlib_get_geometry_reply_t
`xlib.net_supported(feature) -> true|false`         check the _NET_SUPPORTED atom map
`xlib.get_netwn_states(win) -> t`                   get _NET_WM_STATE atom map
`xlib.set_netwn_states(win, t)`                     set _NET_WM_STATE atom map
`xlib.change_netwm_states(win,?,p1[,p2])`           set or reset one or two _NET_WM_STATE atoms
`xlib.get_wm_hints(win) -> hints`                   get WM_HINTS as xlib_icccm_wm_hints_t
`xlib.set_wm_hints(win, hints)`                     set WM_HINTS as xlib_icccm_wm_hints_t
`xlib.get_wm_normal_hints(win) -> hints`            get WM_NORMAL_HINTS as xlib_icccm_wm_size_hints_t
`xlib.set_wm_normal_hints(win, hints)`              set WM_NORMAL_HINTS as xlib_icccm_wm_size_hints_t
`xlib.set_minmax(win,minw,minh,maxw,maxh)`          set min/max part of WM_NORMAL_HINTS
`xlib.get_motif_wm_hints(win) -> hints`             get _MOTIF_WM_HINTS as xlib_motif_wm_hints_t
`xlib.set_motif_wm_hints(win, hints)`               set _MOTIF_WM_HINTS as xlib_motif_wm_hints_t
`xlib.request_frame_extents(win)`                   send _NET_REQUEST_FRAME_EXTENTS
`xlib.frame_extents(win) -> x, y, w, h`             send _NET_FRAME_EXTENTS
`xlib.map(win)`                                     show window
`xlib.unmap(win)`                                   hide window
`xlib.activate(win)`                                activate window
`xlib.minimize(win)`                                minimize window
`xlib.translate_coords(src_win,dst_win,x,y)->x,y`   translate coordinates between windows
`xlib.change_pos(win, x, y)`                        change window position relative to its parent
`xlib.change_size(win, cw, ch)`                     change window client area size
`xlib.get_title(win) -> title`                      get window title
`xlib.set_title(win, title)`                        set window title and icon name
`xlib.query_tree(win) -> win_tree`                  get window root, parent and children
__shm__
`xlib.shm() -> shm_C`                               get C namespace of xlib-shm if server supports shm
__ping protocol__
`xlib.pong(e)`                                      respond to a _NET_WM_PING event
`xlib.set_netwm_ping_info(win)`                     set _NET_WM_PID and WM_CLIENT_MACHINE
__direct access__
`xlib.c`                                            xlib_connection_t
`xlib.C`                                            xlib C namespace
`xlib.check(cookie)`                                check a request cookie for errors
--------------------------------------------------- -----------------------------------------------
