#!/bin/bash
[ "$P" ] || { echo "don't call this directly."; exit 1; }

mkdir -p install.$P

mkdir -p llvm.build.$P
cd llvm.build.$P
cmake $M \
	-DLLVM_TARGETS_TO_BUILD=X86 \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_C_FLAGS="$C -U_FORTIFY_SOURCE" \
	-DCMAKE_CXX_FLAGS="$C -U_FORTIFY_SOURCE" \
	-G "Unix Makefiles" ../llvm.src
cmake --build .
cmake -DCMAKE_INSTALL_PREFIX=../install.$P -P cmake_install.cmake
cd ..

mkdir -p clang.build.$P
cd clang.build.$P
cmake $M \
	-DLLVM_CONFIG=../install.$P/bin/llvm-config \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_C_FLAGS="$C -U_FORTIFY_SOURCE" \
	-DCMAKE_CXX_FLAGS="$C -U_FORTIFY_SOURCE" \
	-G "Unix Makefiles" ../clang.src
cmake --build .
cmake -DCMAKE_INSTALL_PREFIX=../install.$P -P cmake_install.cmake
