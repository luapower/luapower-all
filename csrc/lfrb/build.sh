${X}g++ -c -O2 -std=c++11 $C lfrb.cpp -I.
${X}gcc *.o -shared -o ../../bin/$P/$D $L
${X}ar rcs ../../bin/$P/$A *.o
rm *.o
