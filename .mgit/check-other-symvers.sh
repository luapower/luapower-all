#!/bin/bash
# check for non-glibc symbol versions

[ "${OSTYPE#linux}" = "$OSTYPE" ] && { echo "This script is for Linux"; exit 1; }

check() {
	(
	echo $1
	cd bin/$1
	for f in *.so; do
		s="$(objdump -T "$f" | grep -P '\*UND\*\s+[0-9a-f]+\s+[^\s]+\s+[^\s]+$' | grep -v GLIBC)"
		[ "$s" ] && { echo "$f"; echo "$s"; }
	done
	)
}

check linux64
