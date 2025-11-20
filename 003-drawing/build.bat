@echo off

set "LIBDIR=C:\Program Files (x86)\Windows Kits\10\Lib\10.0.19041.0\um\x86"

nasm -g -fwin32 main.s -o "./.build/main.obj"
lld-link /ENTRY:main /OUT:"./.build/main.exe" /DEBUG "./.build/main.obj" "%LIBDIR%\user32.lib" "%LIBDIR%\kernel32.lib" "%LIBDIR%\gdi32.lib"
