# Copy bridgesupport files from an OSX older than 10.13 to luapower/bridgesupport directory.
# NOTE: Not sure if *.bridgesupport files are copyrightable/redistributable. Use at your own risk.

usage() { echo "Usage: mgit bridgesupport copy VOLUME_DIR"; exit 1; }
[ "$1" == copy ] || usage
[ -d "$2" ] || usage

echo "Copying $2/System/Library/Frameworks/*.bridgesupport to bridgesupport ..."
find "$2/System/Library/Frameworks" -name '*.bridgesupport' -exec cp '{}' bridgesupport \;
