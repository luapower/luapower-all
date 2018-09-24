#!/bin/bash
shopt -s nullglob

describe() {
	echo " Compile and link together LuaJIT, Lua modules, Lua/C modules, C libraries,"
	echo " and other static assets into a single fat executable."
	echo
	echo " Tested with mingw, gcc and clang on Windows, Linux and OSX respectively."
	echo " Written by Cosmin Apreutesei. Public Domain."
}

say() { [ "$VERBOSE" ] && echo "$@"; }
verbose() { say "$@"; "$@"; }
die() { echo "$@" >&2; exit 1; }

# defaults -------------------------------------------------------------------

BLUA_PREFIX=Blua_
BBIN_PREFIX=Bbin_

# note: only the mingw linker is smart to ommit dlibs that are not used.
DLIBS_mingw="gdi32 msimg32 opengl32 winmm ws2_32 ole32"
DLIBS_linux="m dl"
DLIBS_osx=
FRAMEWORKS="ApplicationServices" # for OSX

APREFIX_mingw=
APREFIX_linux=lib
APREFIX_osx=lib

ALIBS="luajit"
MODULES="bundle_loader"
BIN_MODULES=
DIR_MODULES=
ICON_mingw=csrc/bundle/luapower.ico
ICON_osx=csrc/bundle/luapower-icon.png
OSX_ICON_SIZES="16 32 128" # you can add 256 and 512 but the icns will be 0.5M

IGNORE_ODIR=
COMPRESS_EXE=
NOCONSOLE=
VERBOSE=

# list modules and libs ------------------------------------------------------

# usage: P=<platform> $0 basedir/file.lua|.dasl -> file.lua|.dasl
# note: skips test and demo modules, and other platforms modules.
lua_module() {
	local f=$1
	local ext=${f##*.}
	[ "$ext" != lua -a "$ext" != dasl ] && return
	[ "${f%_test.lua}" != $f ] && return
	[ "${f%_demo.lua}" != $f ] && return
	[ "${f#bin/}" != $f -a "${f#bin/$P/}" = $f ] && return
	echo $f
}

# usage: P=<platform> $0 [dir] -> module1.lua|.dasl ...
# note: skips looking in special dirs.
lua_modules() {
	for f in $1*; do
		if [ -d $f ]; then
			[ "${f:0:1}" != "." \
				-a "${f:0:4}" != csrc \
				-a "${f:0:5}" != media \
				-a "${f:0:5}" != .mgit \
			] && \
				lua_modules $f/
		else
			lua_module $f
		fi
	done
}

# usage: P=<platform> $0 -> lib1 ...
alibs() {
	(cd bin/$P &&
		for f in *.a; do
			local m=${f%*.*}   # libz.* -> libz
			echo ${m#$APREFIX} # libz -> z
		done)
}

# compiling ------------------------------------------------------------------

# usage: CFLAGS=... f=file.* o=file.o sym=symbolname $0 CFLAGS... -> file.o
compile_bin_file() {
	local sec=.rodata
	[ $OS = osx ] && sec="__TEXT,__const"
	# symbols must be prefixed with an underscore on OSX and mingw-32bit
	local sym=$sym; [ $OS = osx -o $P = mingw32 ] && sym=_$sym
	# insert a shim to avoid 'address not in any section file' error in OSX/i386
	local shim; [ $P = osx32 ] && shim=".byte 0"
	echo "\
		.section $sec
		.global $sym
		$sym:
			.int label_2 - label_1
		label_1:
			.incbin \"$f\"
		label_2:
			$shim
	" | gcc -c -xassembler - -o $o $CFLAGS "$@"
}

# usage: CFLAGS=... f=file.c o=file.o $0 CFLAGS... -> file.o
compile_c_module() {
	gcc -c -xc $f -o $o $CFLAGS "$@"
}

# usage: [ filename=file.lua ] f=file.lua|- o=file.o $0 CFLAGS... -> file.o
compile_lua_module() {
	./luajit -b -t raw -g $f $o.luac
	local sym=$filename
	[ "$sym" ] || sym=$f
	sym=${sym#bin/$P/lua/}       # bin/<platform>/lua/a.lua -> a.lua
	sym=${sym%.lua}              # a.lua -> a
	sym=${sym%.dasl}             # a.dasl -> a
	sym=${sym//[\-\.\/\\]/_}     # a-b.c/d -> a_b_c_d
	sym=$BLUA_PREFIX$sym f=$o.luac compile_bin_file "$@"
}

# usage: f=file.dasl o=file.o $0 CFLAGS... -> file.o
compile_dasl_module() {
	./luajit dynasm.lua $f | filename=$f f=- compile_lua_module "$@"
}

# usage: f=file.* [name=file.*] o=file.o $0 CFLAGS... -> file.o
compile_bin_module() {
	local name=$name
	[ "$name" ] || name=$f
	local sym=${name//[\-\.\/\\]/_}  # foo/bar-baz.ext -> foo_bar_baz_ext
	sym=$BBIN_PREFIX$sym compile_bin_file "$@"
}

# usage: $0 dir
serialize_dir_listing() {
	echo -n 'return {'
	ls -1F $1 | sed 's/"/\\\\"/g' | while read f; do echo -n "\"$f\","; done
	echo -n '}'
}

# usage: f=dir o=file.o $0 CFLAGS... -> file.o
compile_dir_module() {
	serialize_dir_listing $f > $o.dir
	name=$f f=$o.dir compile_bin_module "$@"
}

sayt() { [ "$VERBOSE" ] && printf "  %-15s %s\n" "$1" "$2"; }

# usage: mtype=type [osuffix=] $0 file[.lua]|.c|.dasl|.* CFLAGS... -> file.o
compile_module() {
	local f=$1; shift

	# disambiguate between file `a.b` and Lua module `a.b`.
	[ -f $f -o -d $f ] || {
		local luaf=${f//\./\/}    # a.b -> a/b
		luaf=$luaf.lua            # a/b -> a/b.lua
		[ -f $luaf ] || die "File not found: $f (nor $luaf)"
		f=$luaf
	}

	# infer file type from file extension
	local x
	if [ "$mtype" ]; then
		x=$mtype
	elif [ -d $f ]; then
		x=dir
	else
		x=${f##*.}             # a.ext -> ext
		[ $x = c -o $x = lua -o $x = dasl ] || x=bin
	fi

	local o=$ODIR/$f$osuffix.o   # a.ext -> $ODIR/a.ext.o
	OFILES="$OFILES $o"  # add the .o file to the list of files to be linked

	# use the cached .o file if the source file hasn't changed, make-style.
	[ -z "$IGNORE_ODIR" -a -f $o -a $o -nt $f ] && return

	# or, compile the source file into the .o file
	sayt $x $f
	mkdir -p `dirname $o`
	f=$f o=$o compile_${x}_module "$@"
}

# usage: $0 file.c CFLAGS... -> file.o
compile_bundle_module() {
	local f=$1; shift
	compile_module csrc/bundle/$f -Icsrc/bundle -Icsrc/luajit/src/src "$@"
}

# usage: o=file.o s="res code..." [f=source_file] $0 -> file.o
compile_resource() {
	OFILES="$OFILES $o"

	# use the cached .o file if the source file hasn't changed, make-style.
	[ -n "$f" ] && [ -z "$IGNORE_ODIR" -a -f $o -a $o -nt $f ] && return

	sayt res $o
	mkdir -p `dirname $o`
	echo "$s" | windres -o $o
}

# add an icon file for the exe file and main window (Windows only)
# usage: $0 file.ico -> _icon.o
compile_icon() {
	[ $OS = mingw ] || return
	local f=$1; shift
	[ "$f" ] || return
	sayt icon $f
	s="100 ICON \"$f\"" o=$ODIR/$f.res.o f=$f compile_resource
}

# add a manifest file to enable the exe to use comctl 6.0
# usage: $0 file.manifest -> _manifest.o
compile_manifest() {
	[ $OS = mingw ] || return
	local f=$1; shift
	[ "$f" ] || return
	sayt manifest $f
	# 24 is RT_MANIFEST from winuser.h
	s="1 24 \"$f\"" o=$ODIR/$f.res.o f=$f compile_resource
}

# auto-generate app version based on last git tag + number of commits after it
app_auto_version() {
	[ "$APPREPO" ] || die "-av option requires -ar option"
	mgit - "$APPREPO" describe --tags --long --always | sed -e 's/\-[^\-]\+$//' | tr '-' '.'
}

# add a VERSIONINFO resource to populate exe's Properties dialog box.
# usage: $0 "Name=Value;..."
# NOTE: $FileDescription is what appears in Task Manager on Windows.
compile_version_info() {
	[ $OS = mingw ] || return
	sayt versioninfo "$VERSIONINFO"
	s="$(echo '
	1 VERSIONINFO
		{
		BLOCK "StringFileInfo" {
			BLOCK "040904b0" {'
			while read -d';' -r pair; do
				IFS='=' read -r key val <<<"$pair"
				echo "				VALUE \"$key\", \"$val\000\""
			done <<<"$1;"
	echo '			}
		}
	}
	')" o=$ODIR/_versioninfo.res.o compile_resource
}

# compile stdin-generated Lua module
# usage: s="Lua code..." $0 -> module.lua.o
compile_virtual_lua_module() {
	local o=$ODIR/$1.lua.o
	sayt vlua $1
	OFILES="$OFILES $o"
	mkdir -p `dirname $o`
	echo "$s" | o=$o filename=$1.lua f=- compile_lua_module
}

compile_bundle_libs() {
	s="return [[$ALIBS]]" compile_virtual_lua_module bundle_libs
}

compile_bundle_appversion() {
	[ "$APPVERSION" ] || return
	[ "$APPVERSION" = "auto" ] && APPVERSION="$(app_auto_version)"
	s="return '$APPVERSION'" compile_virtual_lua_module bundle_appversion
}

# usage: MODULES='mod1 ...' $0 -> $ODIR/*.o
compile_all() {
	say "Compiling modules..."

	# the dir where static .o files are generated
	ODIR=.bundle-tmp/$P
	mkdir -p $ODIR || die "Cannot mkdir $ODIR"

	# the compile_*() functions will add the names of all .o files to this var
	OFILES=

	# the icon has to be linked first, believe it!
	# so we compile it first so that it's added to $OFILES first.
	compile_icon "$ICON"

	# compile all the modules
	for m in $MODULES; do
		compile_module $m
	done
	for m in $BIN_MODULES; do
		mtype=bin compile_module $m
	done
	for d in $DIR_MODULES; do
		mtype=dir compile_module $d
	done

	# compile bundle.c which implements bundle_add_loaders() and bundle_main().
	# bundle.c is a template: it compiles differently for each $MAIN
	local copt
	[ "$MAIN" ] && copt=-DBUNDLE_MAIN=$MAIN
	osuffix=_$MAIN compile_bundle_module bundle.c $copt

	# compile our custom luajit frontend which calls bundle_add_loaders()
	# and bundle_main() on startup.
	compile_bundle_module luajit.c

	# compile a listing of all static libs needed for ffi.load() logic
	compile_bundle_libs

	# compile the auto-generated app version
	compile_bundle_appversion

	# embed the luajit manifest file
	compile_manifest "bin/mingw32/luajit.exe.manifest"

	# generate a VERSIONINFO resource (Windows)
	compile_version_info "$VERSIONINFO"

}

# linking --------------------------------------------------------------------

aopt() { for f in $1; do echo "bin/$P/$APREFIX$f.a"; done; }
lopt() { for f in $1; do echo "-l$f"; done; }
fopt() { for f in $1; do echo "-framework $f"; done; }

# usage: LDFLAGS=... P=platform ALIBS='lib1 ...' DLIBS='lib1 ...' \
#          EXE=exe_file NOCONSOLE=1 $0
link_mingw() {

	local mingw_lib_dir
	if [ $P = mingw32 ]; then
		mingw_lib_dir="$(dirname "$(which gcc)")/../lib"
	else
		mingw_lib_dir="$(dirname "$(which gcc)")/../x86_64-w64-mingw32/lib"
	fi

	local xopt
	# make a windows app or a console app
	[ "$NOCONSOLE" ] && xopt="$xopt -mwindows"

	verbose g++ $LDFLAGS $OFILES -o "$EXE" \
		-static -static-libgcc -static-libstdc++ \
		-Wl,--export-all-symbols \
		-Wl,--whole-archive `aopt "$ALIBS"` \
		-Wl,--no-whole-archive \
		`lopt "$DLIBS"` $xopt
}

# usage: LDFLAGS=... P=platform ALIBS='lib1 ...' DLIBS='lib1 ...' EXE=exe_file $0
link_linux() {
	verbose g++ $LDFLAGS $OFILES -o "$EXE" \
		-static-libgcc -static-libstdc++ \
		-Wl,-E \
		-Lbin/$P \
		-pthread \
		-Wl,--whole-archive `aopt "$ALIBS"` \
		-Wl,--no-whole-archive `lopt "$DLIBS"` \
		-Wl,-rpath,'\$\$ORIGIN'
	chmod +x "$EXE"
}

# usage: LDFLAGS=... P=platform ALIBS='lib1 ...' DLIBS='lib1 ...' EXE=exe_file $0
link_osx() {
	# note: luajit needs these flags for OSX/x64, see http://luajit.org/install.html#embed
	local xopt; [ $P = osx64 ] && xopt="-pagezero_size 10000 -image_base 100000000"
	# note: using -stdlib=libstdc++ because in 10.9+, libc++ is the default.
	verbose g++ $LDFLAGS $OFILES -o "$EXE" \
		-mmacosx-version-min=10.6 \
		-stdlib=libstdc++ \
		-Lbin/$P \
		`lopt "$DLIBS"` \
		`fopt "$FRAMEWORKS"` \
		-Wl,-all_load `aopt "$ALIBS"` $xopt
	chmod +x "$EXE"
	install_name_tool -add_rpath @loader_path/ "$EXE"
	# make a minimal app bundle if necessary
	[ "$NOCONSOLE" ] && make_osx_app
}

link_all() {
	say "Linking $EXE..."
	link_$OS
}

# usage: $0 infile.png outfile.icns
make_icns() {
	local png="$1"
	local icns="$2"
	local iconset="$icns.iconset"
	rm -rf "$iconset"
	mkdir -p "$iconset"
	for i in $OSX_ICON_SIZES; do
		local i2=$((i*2))
		sips -z $i  $i  "$png" --out "$iconset/icon_${i}x${i}.png" >/dev/null
		sips -z $i2 $i2 "$png" --out "$iconset/icon_${i}x${i}@2x.png" >/dev/null
	done
	rm -f "$icns"
	iconutil -c icns -o "$icns" "$iconset" 2>&1 | grep -v "warning: No image found"
	rm -rf "$iconset"
}

# usage: EXE=exefile [ICON=iconfile] $0
make_osx_app() {
	local exename="$(basename "$EXE")"
	local cdir="$EXE.app/Contents"

	# make the app contents dir and move the exe to it
	mkdir -p "$cdir/MacOS"
	mv -f "$EXE" "$cdir/MacOS/$exename"

	# create a bare-minimum info.plist file
	(
		echo '<?xml version="1.0" encoding="UTF-8"?>'
		echo '<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'
		echo '<plist version="1.0">'
		echo '<dict>'
		echo "<key>CFBundleExecutable</key><string>$exename</string>"
		echo "<key>CFBundleIconFile</key><string>icon.icns</string>"
		echo "</dict></plist>"
	) > "$cdir/Info.plist"

	# convert/copy the icon file
	[ "$ICON" ] && {
		local ext="${ICON##*.}"
		local icns="$cdir/Resources/icon.icns"
		mkdir -p "$(dirname "$icns")"
		if [ "$ext" = "png" ]; then
			make_icns "$ICON" "$icns"
		elif [ "$ext" = "icns" ]; then
			cp -f "$ICON" "$icns"
		else
			die "Unknown icon type: $ext"
		fi
	}
}

compress_exe() {
	[ "$COMPRESS_EXE" ] || return
	say "Compressing $EXE..."
	which upx >/dev/null || { say "UPX not found."; return; }
	upx -qqq "$EXE"
}

# usage: P=platform MODULES='mod1 ...' ALIBS='lib1 ...' DLIBS='lib1 ...'
#         MAIN=module EXE=exe_file NOCONSOLE=1 ICON=icon COMPRESS_EXE=1 $0
bundle() {
	say "Bundle parameters:"
	say "  Platform:       " "$OS ($P)"
	say "  Output file:    " "$EXE"
	say "  Modules:        " $MODULES
	say "  Static libs:    " $ALIBS
	say "  Dynamic libs:   " $DLIBS
	say "  Binary Modules: " $BIN_MODULES
	say "  Dir Modules:    " $DIR_MODULES
	say "  Main module:    " $MAIN
	say "  Icon:           " $ICON
	compile_all
	link_all
	compress_exe
	say "Done."
}

# cmdline --------------------------------------------------------------------

usage() {
	echo
	describe
	echo
	echo " USAGE: mgit bundle options..."
	echo
	echo "  -o  --output FILE                  Output executable (required)"
	echo
	echo "  -m  --modules \"FILE1 ...\"|--all|-- Lua (or other) modules to bundle [1]"
	echo "  -a  --alibs \"LIB1 ...\"|--all|--    Static libs to bundle            [2]"
	echo "  -d  --dlibs \"LIB1 ...\"|--          Dynamic libs to link against     [3]"
	echo "  -f  --frameworks \"FRM1 ...\"        Frameworks to link against (OSX) [4]"
	echo "  -b  --bin-modules \"FILE1 ...\"      Files to bundle as binary blobs"
	echo "  -D  --dir-modules \"DIR1 ...\"       Directory listings to bundle as blobs"
	echo
	echo "  -M  --main MODULE                  Module to run on start-up"
	echo
	echo "  -m32                               Compile for 32bit (Windows, OSX)"
	echo "  -z  --compress                     Compress the executable (needs UPX)"
	echo "  -w  --no-console                   Hide console (Windows)"
	echo "  -w  --no-console                   Make app bundle (OSX)"
	echo "  -i  --icon FILE.ico                Set icon (Windows)"
	echo "  -i  --icon FILE.png                Set icon (OSX; requires -w)"
	echo "  -vi --versioninfo \"Name=Val;...\"   Set VERSIONINFO fields (Windows)"
	echo "  -av --appversion VERSION|auto      Set bundle.appversion to VERSION"
	echo "  -ar --apprepo REPO                 Git repo for -av auto"
	echo
	echo "  -ll --list-lua-modules             List Lua modules"
	echo "  -la --list-alibs                   List static libs (.a files)"
	echo
	echo "  -C  --clean                        Ignore the object cache"
	echo
	echo "  -v  --verbose                      Be verbose"
	echo "  -h  --help                         Show this screen"
	echo
   echo " Passing -- clears the list of args for that option, including implicit args."
	echo
	echo " [1] .lua, .c and .dasl are compiled, other files are added as blobs."
	echo
	echo " [2] implicit static libs:           "$ALIBS0
	echo " [3] implicit dynamic libs:          "$DLIBS0
	echo " [4] implicit frameworks:            "$FRAMEWORKS0
	echo
	exit
}

# usage: $0 [force_32bit]
set_platform() {

	# detect platform
	P=`.mgit/platform.sh`
	[ "$P" ] || die "Unable to set platform."
	[ "$1" ] && P=${P/64/32}

	# set platform-specific variables
	OS=${P%[0-9][0-9]}
	[ "$DLIBS" ]   || eval DLIBS=\$DLIBS_$OS
	[ "$APREFIX" ] || eval APREFIX=\$APREFIX_$OS
	[ "$ICON" ]    || eval ICON=\$ICON_$OS

	[ $P = osx32 ] && { CFLAGS="-arch i386";   LDFLAGS="-arch i386"; }
	[ $P = osx64 ] && { CFLAGS="-arch x86_64"; LDFLAGS="-arch x86_64"; }
}

parse_opts() {
	while [ "$1" ]; do
		local opt="$1"; shift
		case "$opt" in
			-o  | --output)
				EXE="$1"; shift;;
			-m  | --modules)
				[ "$1" = -- ] && MODULES= || \
					[ "$1" = --all ] && MODULES="$(lua_modules)" || \
					MODULES="$MODULES $1"
				shift
				;;
			-b | --bin-modules)
				BIN_MODULES="$BIN_MODULES $1"; shift;;
			-D | --dir-modules)
				DIR_MODULES="$DIR_MODULES $1"; shift;;
			-M  | --main)
				MAIN="$1"; MODULES="$MODULES $1"; shift;;
			-a  | --alibs)
				[ "$1" = -- ] && ALIBS= || \
					[ "$1" = --all ] && ALIBS="$(alibs)" || \
						ALIBS="$ALIBS $1"
				shift
				;;
			-d  | --dlibs)
				[ "$1" = -- ] && DLIBS= || DLIBS="$DLIBS $1"
				shift
				;;
			-f  | --frameworks)
				[ "$1" = -- ] && FRAMEWORKS= || FRAMEWORKS="$FRAMEWORKS $1"
				shift
				;;
			-ll | --list-lua-modules)
				lua_modules; exit;;
			-la | --list-alibs)
				alibs; exit;;
			-C  | --clean)
				IGNORE_ODIR=1;;
			-m32)
				set_platform m32;;
			-z  | --compress)
				COMPRESS_EXE=1;;
			-i  | --icon)
				ICON="$1"; shift;;
			-w  | --no-console)
				NOCONSOLE=1;;
			-vi | --versioninfo)
				VERSIONINFO="$VERSIONINFO;$1"; shift;;
			-av  | --appversion)
				APPVERSION="$1"; shift;;
			-ar  | --apprepo)
				APPREPO="$1"; shift;;
			-h  | --help)
				usage;;
			-v | --verbose)
				VERBOSE=1;;
			*)
				echo "Invalid option: $opt"
				usage "$opt"
				;;
		esac
	done
	[ "$EXE" ] || usage
}

ALIBS0="$ALIBS"
DLIBS0="$DLIBS"
FRAMEWORKS0="$FRAMEWORKS"

set_platform
parse_opts "$@"
bundle
