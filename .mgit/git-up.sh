#!/bin/bash
# git add/commit/push combo on the current repo

msg="$1"
[ "$msg" ] || msg="unimportant"
git add -A
git commit -m "$msg"
git push
