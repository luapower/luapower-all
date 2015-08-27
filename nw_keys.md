---
tagline:   native widgets key codes
---

## Types of keys

Keys on a keyboard are classified as follows:

~~~
naming			represents			numlock-sensitive		left-right distinction
--------------	-----------------	--------------------	-----------------------
key				functional keys	yes						no
vkey				virtual keys		yes						yes
pkey				physical keys		no							yes
~~~

Functional keys are useful for creating shortcuts, while physical keys are useful for games.
Virtual keys are not generally useful, except when you need to distinguish
between left/right key variations or between numapd keys and standalone cursor keys,
but you also need to respect the numlock key.

## Full list

Here's the full list of functional keys and their corresponding virtual keys.
You get physical keys instead of virtual keys if you set the `ignore_numlock` option,
in which case the keyboard API will act as if numlock is always on.

~~~
key				vkeys									comments
-----------------------------------------------------------------
; 															US keyboard
=
,
-
.
/															US keyboard
`															US keyboard
[															US keyboard
\\															US keyboard
]															US keyboard
'															US keyboard

backspace
tab
space
esc

F1-F10

F11														taken on mac (show desktop)
F12														taken on mac (show dashboard)

F13														osx only
F14														osx only; taken (brightness down)
F15														osx only; taken (brightness up)
F16														mac keyboard
F17														mac keyboard
F18														mac keyboard
F19														mac keyboard

capslock													no key-up timing on osx
numlock													windows only; light always off on OSX
printscreen												windows only; taken (screen capture)
scrolllock												windows only
break														windows only

num0-num9

num.
num*
num+
num-
num/
numclear													separate key on mac keyboard

lwin														windows only
rwin														windows only
menu														win keyboard
num=														osx only

0-9
A-Z

ctrl				lctrl				rctrl
alt				lalt				ralt
command			lcommand			rcommand			osx only

left				left!				numleft			num... variants are windows only
up					up!				numup
right				right!			numright
down				down!				numdown

pageup			pageup!			numpageup
pagedown			pagedown!		numpagedown
end				end!				numend
home				home!				numhome
insert			insert!			numinsert
delete			delete!			numdelete
enter				enter!			numenter

help														osx only; no keydown event

mute
volumedown
volumeup
~~~

> Note: ctrl+numlock doesn't change the numlock state. Same with ctrl+scrolllock.

## Crossing cultures

Windows keyboards can be used on OSX and Mac keyboards can be used on Windows.
Each OS will try to simulate its own keyboard on the foreign keyboard.
For example, the numlock key on the Windows keyboard is mapped to numclear in OSX,
because that's where the typical Mac user expects numclear to be, regardless
of what is written on the key cap.

Here's how the mappings go:


### Windows Keyboard on OSX

~~~
win keyboard		key on OSX
----------------------------------
lwin					lcommand
rwin					rcommand
menu					menu

numlock				numclear

printscreen			F13
scrolllock			F14
break					F15

insert!				help
~~~


### Mac Keyboard on Windows

If you have a mac keyboard and a windows box, please fill these up.

~~~
mac keyboard		key on Windows
----------------------------------
F13					?
F14					?
F15					?
F16					?
F17					?
F18					?
F19					?

num=					?
help					?
numclear				?
~~~
