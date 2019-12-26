#!/bin/sh
# make daily bundles for each platform, for downloading from the homepage.
# to be added as a daily cron job.

# NOTE: no longer used. We now have a single download button on the homepage
# that downloads the full archive for all platforms.

die() { echo "$@" >&2; exit 1; }
cd "$(dirname "$0")" || die "Could not cd to script's dir"
[ -d luapower ] || die "luapower dir not found"
outdir="$PWD/files"; [ -d "$outdir" ] || die "Directory \"$outdir\" not found"
which zip >/dev/null || die "zip not found"

files() {
	(platform="$1"
	cd luapower
	mgit ls | while read pkg; do
		mgit - $pkg ls-files | while read f; do
			[ "$f" = "${f%.exclude}" ] && \
			[ "$f" = "${f#.mgit/}" ] && \
			[ "${f#bin/*/}" = "${f#bin/$platform/}" ] && \
				echo "luapower/$f"
		done
	done)
}

for p in mingw32 mingw64 osx32 osx64; do
	echo "packing $p..."
	outfile="$outdir/luapower-$p.zip"
	tmpfile="$outfile.$$"
	files $p | zip -@ "$tmpfile" && mv "$tmpfile" "$outfile" || rm "$tmpfile"
done

for p in linux32 linux64; do
	echo "packing $p..."
	outfile="$outdir/luapower-$p.tar.gz"
	tmpfile="$outfile.$$"
	files $p | tar cvzf "$tmpfile" -T - && mv "$tmpfile" "$outfile" || rm "$tmpfile"
done
