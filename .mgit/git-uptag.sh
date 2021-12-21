#!/bin/bash
# udate the current tag to point to the current commit

tag="$(git describe --tags --abbrev=0 2>/dev/null)"
[ "$tag" ] || usage "No current tag to update. Make a tag first."
git tag -f "$tag"
git push -f --tags
