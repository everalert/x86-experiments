@echo off

set "i=%1"

:: NOTE: edit this if your win32 lib files are in a different directory
set _LIBDIR_="C:\Program Files (x86)\Windows Kits\10\Lib\10.0.19041.0\um\x86"

:: TODO: /COPY to duplicate sub-project
:: TODO: /CLEAN to remove sub-project build directory
:: TODO: allow LIBDIR as input
set _FWDARGS_=
:ARGPARSE
	set _=%~1
	if "%_:~,1%" == "/" (
		if /i "%~1" == "/BUILD"	( set _M_=1 & set _B_=1
		) else if /i "%~1" == "/RUN" ( set _M_=1 & set _R_=1
		) else if /i "%~1" == "/000" ( set _PROJECT_=000-template
		) else if /i "%~1" == "/001" ( set _PROJECT_=001-console
		) else if /i "%~1" == "/002" ( set _PROJECT_=002-window
		) else if /i "%~1" == "/003" ( set _PROJECT_=003-drawing
		) else if /i "%~1" == "/004" ( set _PROJECT_=004-rawinput
		)
	) else set _FWDARGS_=%_FWDARGS_% %1
	set _=
	shift
	if not "%~1" == "" goto ARGPARSE

if not defined _PROJECT_ (
	echo No sub-project selected. Use /000, /001, etc.; see b.bat for list.
	goto END
)

if not defined _M_ (
	echo No mode selected. Use /BUILD, /RUN or both.
	goto END
) 

pushd %_PROJECT_%
if defined _B_ (
	if not exist ".build" mkdir ".build"
	call "./build.bat" /LIBDIR %_LIBDIR_% %_FWDARGS_%
)
if defined _R_ (
	if not exist ".build" echo .build directory not found, run with /BUILD first
	if exist ".build" call "./run.bat" %_FWDARGS_%
)
popd

:END
