@echo off

set LIBDIR="C:\Program Files (x86)\Windows Kits\10\Lib\10.0.19041.0\um\x86"
:ARGPARSE
	set _=%~1
	if "%_:~,7%" == "/LIBDIR" ( 
		set LIBDIR="%~2"
		shift
	)
	set _=
	shift
	if not "%~1" == "" goto ARGPARSE

nasm -g -fwin32 main.s -o "./.build/main.obj"
lld-link /ENTRY:main /OUT:"./.build/main.exe" /DEBUG "./.build/main.obj" %LIBDIR%\user32.lib %LIBDIR%\kernel32.lib %LIBDIR%\gdi32.lib
