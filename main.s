;nasm -fwin32 msgboxA.asm
;GoLink /entry _main msgboxA.obj user32.dll kernel32.dll
;msgboxA.exe

; testing asm setup
; code from https://vulnerablespace.blogspot.com/2015/06/nasm101-0x01-calling-win32-api-functions.html
 
extern _ExitProcess@4
extern _MessageBoxA@16
 
global _main
 
section .data
    msg		db "Vulnerable Space",0
    ttl		db "Welcome",0
 
section .text
_main:
    push	word 0x00			; MB_OK = 0
    push	dword ttl			; "Welcome"
    push	dword msg       	; "Vulnerable Space"
    push	dword 0         	; handle to owner window
    call	_MessageBoxA@16 	; in user32.dll
     
    push	0               	; no error
    call	_ExitProcess@4  	; in kernel32.dll
