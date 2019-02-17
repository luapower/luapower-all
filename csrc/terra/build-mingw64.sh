export L="
-llua51 -lshlwapi -ldbghelp -lshell32 -lpsapi -limagehlp -lversion -lole32 -luuid
-s -static-libgcc -static-libstdc++
-Wl,-Bstatic -lstdc++ -lpthread -Wl,-Bdynamic
-Wl,--version-script=../../terra.version"
P=mingw64 D=terra.dll A=terra.a ./build.sh
