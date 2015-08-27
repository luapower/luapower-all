---
tagline: complex text shaping
---

## `local harfbuzz = require'harfbuzz'`

A ffi binding of [HarfBuzz][harfbuzz lib], a library for OpenType complex text shaping.

work in progress...

There's a quick demo to try out in the meantime (for which you'll need the freetype package).

TODO: integrate more from this: https://github.com/lxnt/ex-sdl-freetype-harfbuzz/blob/master/ex-sdl-freetype-harfbuzz.c


[harfbuzz lib]: http://www.freedesktop.org/wiki/Software/HarfBuzz/

## Building

After upgrading harfbuzz, building it requires removing the included .hh files
and recreating them with [Ragel](https://www.colm.net/open-source/ragel/).
Ragel builds with luapower's toolchain just fine:

Get it:

	wget https://www.colm.net/files/ragel/ragel-6.9.tar.gz
	tar xfv ragel-6.9.tar.gz
	cd ragel-6.9

Linux / OSX:

	./configure
	make
	sudo make install

Windows:

	sh configure
	make
	cp ragel/ragel.exe <mingw-install-dir>/bin
