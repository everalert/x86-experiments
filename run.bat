@echo off

set "i=%1"

if "%i%"=="000" set d=000-template & goto :run
if "%i%"=="001" set d=001-createwindow & goto :run
echo sub-project not found
goto :end

:run
pushd %d%
if not exist ".build" echo .build directory not found, run build.bat first & goto :end
call "./run.bat"
popd

:end
