#!/bin/sh
# pull all repos and invalidate the cache on the ones that were updated.
# to be added as an hourly cron job.

PWD0="$(dirname "$0")"
cd "$PWD0/luapower" || exit 1

check() { grep -q -v 'Already up-to-date.'; }

mgit luapower-repos pull | check && REPOS_UPDATED=1

UNCLONED="$(mgit ls-uncloned)"
[ "$UNCLONED" ] && mgit clone-all
UNCLONED="$(mgit ls-uncloned)"
[ "$UNCLONED" ] && "There are still uncloned repos: $UNCLONED."

for pkg in $(mgit ls); do
	mgit - $pkg pull | check && "$PWD0/clear-cache" $pkg && "Updated: $pkg."
done

cd "$PWD0" && git pull | check && "Updated: website."

[ "$REPOS_UPDATED" ] && ./clear-cache
