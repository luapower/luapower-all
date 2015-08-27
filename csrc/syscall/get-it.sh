#!/bin/bash

cd "$(dirname "$0")" || exit 1

git clone https://github.com/justincormack/ljsyscall.git
rm -rf ../../syscall
cp -rf ljsyscall/syscall ../..
cp -rf ljsyscall/syscall.lua ../../
