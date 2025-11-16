@echo off

nasm -fwin32 main.s -o "./.build/main.obj"
golink /entry _main "./.build/main.obj" user32.dll kernel32.dll
