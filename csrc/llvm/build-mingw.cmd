@echo off
setlocal EnableDelayedExpansion

if [%1] == [] echo don't call this directly. & exit

cat AddLLVM.cmake.patch | patch -N llvm.src/cmake/modules/AddLLVM.cmake

REM remove MSYS from PATH because CMAKE is dumb.
set $line=%path%
for %%a in ("%path:;=";"%") do (
    echo %%a | find /i "msys" >nul && echo Removed %%a from PATH to please CMAKE. || set $newpath=!$newpath!;%%a
)
set $newpath=%$newpath:"=%
set path=!$newpath:~1!

md install.mingw%1 2>nul

md llvm.build.mingw%1 2>nul
cd llvm.build.mingw%1
cmake -DLLVM_TARGETS_TO_BUILD=X86 -DCMAKE_BUILD_TYPE=Release -G "MinGW Makefiles" ../llvm.src
cmake --build .
cmake -DCMAKE_INSTALL_PREFIX=../install.mingw%1 -P cmake_install.cmake
cd ..

md clang.build.mingw%1 2>nul
cd clang.build.mingw%1
cmake -DLLVM_CONFIG=../install.mingw%1/bin/llvm-config -DCMAKE_BUILD_TYPE=Release -G "MinGW Makefiles" ../clang.src
cmake --build .
cmake -DCMAKE_INSTALL_PREFIX=../install.mingw%1 -P cmake_install.cmake
