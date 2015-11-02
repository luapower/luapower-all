${X}g++ -c -O2 $C clipper_c.cpp -I. -fvisibility=hidden
${X}g++ *.o -shared -o ../../bin/$P/$D -L. $L
${X}ar rcs ../../bin/$P/$A *.o
rm *.o
