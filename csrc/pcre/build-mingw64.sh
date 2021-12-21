P=mingw64 C="
-DPCRE_EXP_DECL=__declspec(dllexport)
-DPCRE_EXP_DEFN=__declspec(dllexport)
-DPCRE_EXP_DATA_DEFN=__declspec(dllexport)
" L="-s -static-libgcc" D=pcre.dll A=pcre.a ./build.sh
