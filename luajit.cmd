@echo off
rem luajit wrapper that runs the 32bit luajit on 32bit windows
rem and the 64bit luajit on 64bit windows.
if [%PROCESSOR_ARCHITECTURE%] == [AMD64] goto win64
if [%PROCESSOR_ARCHITEW6432%] == [AMD64] goto win64
call "%~dp0bin\mingw32\luajit.exe" %*
goto end
:win64
call "%~dp0bin\mingw64\luajit.exe" %*
:end
