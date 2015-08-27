#!/bin/bash

# git chmod +x all .sh files in the current repo
git ls-files | \
	while read f; do
		[ "${f##*.}" = "sh" ] && {
			echo "updating '$f'"
			chmod +x "$f"
			git update-index --chmod=+x "$f"
		}
	done
