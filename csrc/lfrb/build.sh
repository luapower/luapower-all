g++ -c -O2 -std=c++11 $C lfrb.cpp -I.
gcc *.o -shared -o ../../bin/$P/$D $L
ar rcs ../../bin/$P/$A *.o
rm *.o
