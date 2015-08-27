#!/bin/bash
# increment the first number from inside current tag (if any) and push tags

tag="$(git describe --tags --abbrev=0 2>/dev/null)"
if [[ $tag =~ ([^0-9]*)([0-9]+)(.*) ]]; then
	s1="${BASH_REMATCH[1]}"
	n="${BASH_REMATCH[2]}"
	s2="${BASH_REMATCH[3]}"
else
	s1="r"
	n="0"
	s2=""
fi
tag1="$s1$((n+1))$s2"
echo "Bumping version: $tag -> $tag1"
echo "Press any key to continue, Ctrl+C to quit."
read

git tag "$tag1"
git push --tags
