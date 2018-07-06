---
tagline: native windows key codes
---

## Using the keyboard

Keyboards are used differently depending on purpose, which can be text input,
navigation, editing, shortcuts and other functions.

For text input what is being typed is determined by a combination of physical
layout, logical layout input method, capslock state, numlock state,
shift state, key pause and repeat intervals.
Since all this is very complex and involves various user settings,
this is entirely serviced by OS: we just get an event with one or more
unicode code points representing what is being typed.

For navigation the physical location of the keys matters. WASD games use
keys normally used for text input (thus layout-dependent) for the purpose
of navigation, so there needs to be a way to identify character and
punctuation keys based on their physical positon on the standard
US keyboard regerdless of the keyboard's actual layout. This also
creates the need to get the keycap name for those keys. Games also want
to ignore the numlock and capslock states, and may want to distinguish
between left and right modifier keys.

Editing keys (Tab, Enter), as well as function, control and modifier keys
are universal, but not all of them are available between PC, Mac and laptop
keyboards.

Shortcuts involving character and punctuation keys must use layout-dependent
keys so there needs to be a way to query the pressed state of character
and punctuation keys based on the the current layout. Most shortcuts don't
distinguish between left and right modifiers but some do.

For shortcuts there's also the issue of certain key combinations being
used by the OS and what these are is different beteween Windows,
OSX and Linux so care must be taken not to use those. And then
there's cultural differences that need to be accounted for like how
Windows' Ctrl+C needs to be Command+C on a Mac.

## Key names

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

F11														taken on Mac (show desktop)
F12														taken on Mac (show dashboard)

F13														OSX only
F14														OSX only; taken (brightness down)
F15														OSX only; taken (brightness up)
F16														Mac keyboard
F17														Mac keyboard
F18														Mac keyboard
F19														Mac keyboard

capslock													no key-up timing on OSX
numlock													Windows only; light always off on OSX
printscreen												Windows only; taken (screen capture)
scrolllock												Windows only
break														Windows only

num0-num9

num.
num*
num+
num-
num/
numclear													separate key on Mac keyboard

lwin														Windows only
rwin														Windows only
menu														Windows keyboard
num=														OSX only

0-9
A-Z

ctrl				lctrl				rctrl
alt				lalt				ralt
command			lcommand			rcommand			OSX only

left				left!				numleft			num... variants are Windows only
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

help														OSX only; no keydown event

mute
volumedown
volumeup
~~~

> Note: ctrl+numlock doesn't change the numlock state. Same with ctrl+scrolllock.

## Crossing cultures

Windows keyboards can be used on OSX and Mac keyboards can be used on Windows.
Each OS will try to simulate its own keyboard on the foreign keyboard.
For example, the numlock key on the Windows keyboard is mapped to numclear
in OSX, because that's where the typical Mac user expects numclear to be,
regardless of what is written on the key cap.

Here's how the mappings go:


### Windows keyboard on OSX

~~~
Windows keyboard		key on OSX
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


### Mac keyboard on Windows

If you have a Mac keyboard on a Windows box, please fill these up.

~~~
Mac keyboard		key on Windows
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
