@echo off

set LIBDIR_UM="C:\Program Files (x86)\Windows Kits\10\Lib\10.0.22621.0\um\x86"
set LIBDIR_KM="C:\Program Files (x86)\Windows Kits\10\Lib\10.0.22621.0\km\x86"
:ARGPARSE
	set _=%~1
	if "%_:~,7%" == "/LIBDIR_UM" ( 
		set LIBDIR_UM="%~2"
		shift
	) else if "%_:~,7%" == "/LIBDIR_KM" ( 
		set LIBDIR_KM="%~2"
		shift
	)
	set _=
	shift
	if not "%~1" == "" goto ARGPARSE

nasm -g -fwin32 main.s -o "./.build/main.obj"
lld-link /ENTRY:main /OUT:"./.build/main.exe" /DEBUG "./.build/main.obj" %LIBDIR_UM%\user32.lib %LIBDIR_UM%\kernel32.lib %LIBDIR_UM%\gdi32.lib %LIBDIR_KM%\hidparse.lib
