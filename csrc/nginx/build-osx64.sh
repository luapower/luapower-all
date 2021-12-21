P=osx64 E=nginx C="-mmacosx-version-min=10.9" L="" ./build.sh
install_name_tool -add_rpath @loader_path/ ../../bin/osx64/nginx
