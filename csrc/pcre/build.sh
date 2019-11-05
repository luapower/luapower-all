[ "$P" ] || exit 1
C="$C *.c
-DHAVE_CONFIG_H=1
-DSUPPORT_PCRE8=1
-DSUPPORT_UCP=1
-DSUPPORT_JIT=1
-DHAVE_MEMMOVE=1
-DPCRE_EXP_DECL=__declspec(dllexport)
-DPCRE_EXP_DEFN=__declspec(dllexport)
-DPCRE_EXP_DATA_DEFN=__declspec(dllexport)
"
${X}gcc -c -O3 $C -Wall -I. $files
${X}gcc *.o -shared -o ../../bin/$P/$D $L
rm -f      ../../bin/$P/$A
${X}ar rcs ../../bin/$P/$A *.o
rm *.o
