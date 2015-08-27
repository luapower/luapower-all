(
echo "--libexif/exif-loader.h from $(head -1 WHAT)"
echo "require'ffi'.cdef[["
cpp libexif/exif-loader.h -I. | grep -v "^#" | sed '/^$/d'
echo "]]"
) > ../../libexif_h.lua
