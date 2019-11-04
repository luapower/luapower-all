#!/bin/bash
# check glibc symbol versions on all libs and report anything > GLIBC 2.7

[ "${OSTYPE#linux}" = "$OSTYPE" ] && { echo "This script is for Linux"; exit 1; }

check() {
	echo $1
	(cd $1; shift
	for f in $@; do
		s="$(objdump -T $f | grep GLIBC_ | grep -v 'GLIBC_2\.[0-7][\ \.]')"
		[ "$s" ] && printf "%-20s %s\n" "$f" "$s"
	done
	)
}

check bin/linux64 *.so luajit
check bin/linux64/clib *.so
