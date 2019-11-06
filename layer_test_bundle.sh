.mgit/bundle.sh -M layer_test -z -v -w -o bin/layer_test.exe \
   -a "cairo pixman png z boxblur freetype harfbuzz fribidi unibreak xxhash layer" \
   -m "layer_test glue box2d events time color bundle fs* cairo* testui layer_h layer.lua
		winapi.lua winapi/* nw* bitmap* pp*
		media/fonts/OpenSans-Regular.ttf
		media/fonts/Amiri-Regular.ttf
		lorem_ipsum.txt
		"

cd bin
./layer_test.exe
