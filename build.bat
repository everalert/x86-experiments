@echo off

set "i=%1"

if "%i%"=="000" set d=000-template & goto :run
echo sub-project not found
goto :end

:run
pushd %d%
if not exist ".build" mkdir ".build"
call "./build.bat"
popd

:end
