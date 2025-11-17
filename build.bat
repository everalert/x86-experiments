@echo off

set "i=%1"

if "%i%"=="000" set d=000-template & goto :build
if "%i%"=="001" set d=001-console & goto :build
if "%i%"=="002" set d=002-window & goto :build
echo sub-project not found
goto :end

:build
pushd %d%
if not exist ".build" mkdir ".build"
call "./build.bat"
popd

:end
