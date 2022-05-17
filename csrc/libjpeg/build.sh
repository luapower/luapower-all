[ "$P" ] || exit 1
src_dir="$PWD/src"
rm -rf "$build_dir"
mkdir -p "$build_dir"
cd "$build_dir" || exit 1
cmake -G "$M" "$src_dir"
make clean
make jpeg
strip "$build_dir/$DI"
cp -f "$build_dir/$DI" "$src_dir/../../../bin/$P/$D"
make jpeg-static
cp -f "$build_dir/$AI" "$src_dir/../../../bin/$P/$A"
make clean
cd "$src_dir"
rm -rf "$build_dir"
