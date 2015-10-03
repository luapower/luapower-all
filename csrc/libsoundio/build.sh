g++ -c -O2 -std=c++11 $C \
	src/channel_layout.cpp src/dummy.cpp src/os.cpp src/ring_buffer.cpp \
	src/soundio.cpp src/util.cpp -Isrc -I.
gcc *.o -shared -o ../../bin/$P/$D $L
ar rcs ../../bin/$P/$A *.o
rm *.o
