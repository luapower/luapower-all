<<<<<<< HEAD
P=mingw32 D=terra.dll ./build-manually.sh
=======
export L="
-llua51 -lshlwapi -ldbghelp -lshell32 -lpsapi -limagehlp
-s -static-libgcc -static-libstdc++
-Wl,-Bstatic -lstdc++ -lpthread -Wl,-Bdynamic
-Wl,--version-script=../../terra.version"
P=mingw32 D=terra.dll A=terra.a ./build.sh
>>>>>>> d17849af2aaabad79f8193e42b4dc3d3c7554545
