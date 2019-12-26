#!/bin/bash
# tag the luapower-all repo with the current date if there are new changes.
cd ~/luapower || exit 1

last_tag="$(git tag | tail -1)"
commit_last_tag="$(git rev-list -n 1 "$last_tag")"
commit_last="$(git rev-parse HEAD)"
echo "commit of last tag: $commit_last_tag"
echo "last commit:        $commit_last"
if [ "$commit_last_tag" = "$commit_last" ]; then
    echo "nothing to tag."
else
    tag="$(date +%Y-%m-%d)"
    git tag -f "$tag"
    git push -f --tags
fi
