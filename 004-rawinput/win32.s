%ifndef	_WIN32_S_
%define	_WIN32_S_


; FUNCTIONS

extern _GetModuleHandleA@4			; kernel32.dll
extern _GetStdHandle@4				; kernel32.dll
extern _AttachConsole@4				; kernel32.dll
extern _GetConsoleWindow@0			; kernel32.dll
extern _WriteConsoleA@20			; kernel32.dll
extern _ExitProcess@4				; kernel32.dll
extern _VirtualAlloc@16				; kernel32.dll
extern _VirtualFree@12				; kernel32.dll
extern _GetLastError@0				; kernel32.dll
extern _SetLastError@4				; kernel32.dll
extern _FormatMessageA@28			; kernel32.dll
extern _Sleep@4						; kernel32.dll

extern _MessageBoxA@16				; user32.dll
extern _CreateWindowExA@48			; user32.dll
extern _DestroyWindow@4				; user32.dll
extern _GetMessageA@16				; user32.dll
extern _PeekMessageA@20				; user32.dll
extern _TranslateMessage@4			; user32.dll
extern _DispatchMessageA@4			; user32.dll
extern _PostQuitMessage@4			; user32.dll
extern _DefWindowProcA@16			; user32.dll
extern _LoadImageA@24				; user32.dll
extern _RegisterClassExA@4			; user32.dll
extern _AdjustWindowRect@12			; user32.dll
extern _ValidateRect@8				; user32.dll
extern _InvalidateRect@12			; user32.dll
extern _BeginPaint@8				; user32.dll
extern _EndPaint@8					; user32.dll
extern _GetDC@4						; user32.dll
extern _ReleaseDC@8					; user32.dll
extern _GetClientRect@8				; user32.dll
extern _GetSystemMetrics@4			; user32.dll
extern _SetTimer@16					; user32.dll

extern _CreateCompatibleDC@4		; gdi32.dll
extern _DeleteDC@4					; gdi32.dll
extern _GetObject@12				; gdi32.dll
extern _DeleteObject@4				; gdi32.dll
extern _SelectObject@8				; gdi32.dll
extern _SetDIBits@28				; gdi32.dll
extern _StretchDIBits@52			; gdi32.dll
extern _StretchBlt@44				; gdi32.dll
extern _CreateDIBSection@24			; gdi32.dll


; STRUCTURES

struc RECT
	.Lf								resd 1
	.Tp								resd 1
	.Rt								resd 1
	.Bt								resd 1
endstruc

struc PAINTSTRUCT
	.hDC							resd 1
	.fErase							resd 1
	.rcPaint						resb RECT_size
	.fRestore						resd 1
	.fIncUpdate						resd 1
	.rgbReserved					resb 32
endstruc

struc WNDCLASSEXA
	.cbSize							resd 1
	.style							resd 1
	.lpfnWndProc					resd 1
	.cbClsExtra						resd 1
	.cbWndExtra						resd 1
	.hInstance						resd 1
	.hIcon							resd 1
	.hCursor						resd 1
	.hbrBackground					resd 1
	.lpszMenuName					resd 1
	.lpszClassName					resd 1
	.hIconSm						resd 1
endstruc

struc BITMAPINFOHEADER
	.biSize							resd 1
	.biWidth						resd 1
	.biHeight						resd 1
	.biPlanes						resw 1
	.biBitCount						resw 1
	.biCompression					resd 1
	.biSizeImage					resd 1
	.biXPelsPerMeter				resd 1
	.biYPelsPerMeter				resd 1
	.biClrUsed						resd 1
	.biClrImportant					resd 1
endstruc

struc MINMAXINFO
	.ptReserved						resb POINT_size
	.ptMaxSize						resb POINT_size
	.ptMaxPosition					resb POINT_size
	.ptMinTrackSize					resb POINT_size
	.ptMaxTrackSize					resb POINT_size
endstruc

struc POINT
	.x								resd 1
	.y								resd 1
endstruc


; CONSTANTS

section .data

	NULL							equ 0
	ATTACH_PARENT_PROCESS			equ -1
	INVALID_VALUE_HANDLE			equ -1
	STD_OUTPUT_HANDLE				equ -11
	IDI_APPLICATION					equ 0x7F00
	IDC_ARROW						equ 0x7F00
	COLOR_WINDOWFRAME				equ 6
	LR_DEFAULTSIZE					equ 0x00000040
	CW_USEDEFAULT					equ	0x80000000
	WM_DESTROY						equ 0x0002
	WM_SIZE							equ 0x0005
	WM_PAINT						equ 0x000F
	WM_CLOSE						equ 0x0010
	WM_ACTIVATEAPP					equ 0x001C
	WM_GETMINMAXINFO				equ 0x0024
	WM_EXITSIZEMOVE					equ 0x0232
	CS_VREDRAW						equ	0x0001
	CS_HREDRAW						equ	0x0002
	CS_OWNDC						equ	0x0020
	WS_SHOWNORMAL					equ 1
	WS_VISIBLE						equ 0x10000000
	WS_OVERLAPPEDWINDOW				equ 0x00CF0000
	WS_EX_CLIENTEDGE				equ 0x00000200
	MB_OK							equ 0x00
	MB_ICONEXCLAMATION				equ 0x30
	MEM_COMMIT						equ 0x00001000
	MEM_RESERVE						equ 0x00002000
	MEM_DECOMMIT					equ 0x00004000
	MEM_RELEASE						equ 0x00008000
	PAGE_READONLY					equ 0x02
	PAGE_READWRITE					equ 0x04
	BI_RGB							equ 0
	IMAGE_BITMAP					equ 0 ; C:\Program Files (x86)\Windows Kits\10\Include\<ver>\um\winuser.h
	IMAGE_ICON						equ 1
	IMAGE_CURSOR					equ 2
	DIB_RGB_COLORS					equ 0
	DIB_PAL_COLORS					equ 1
	ROP_SRCCOPY						equ	0x00CC0020 ; just SRCCOPY in wingdi.h
	FORMAT_MESSAGE_ALLOCATE_BUFFER	equ 0x00000100
	FORMAT_MESSAGE_IGNORE_INSERTS	equ 0x00000200
	FORMAT_MESSAGE_FROM_STRING		equ 0x00000400
	FORMAT_MESSAGE_FROM_SYSTEM		equ 0x00001000
	ERROR_ACCESS_DENIED				equ 0x00000005
	GDI_ERROR						equ	0xFFFFFFFF
	PM_NOREMOVE						equ 0x0000
	PM_REMOVE						equ 0x0001
	PM_NOYIELD						equ 0x0002

	str_RegisterClassExA			db "RegisterClassExA",0
	str_CreateWindowExA				db "CreateWindowExA",0
	str_GetModuleHandleA			db "GetModuleHandleA",0
	str_AttachConsole				db "AttachConsole",0
	str_GetStdHandle				db "GetStdHandle",0
	str_GetConsoleWindow			db "GetConsoleWindow",0
	str_WriteConsoleA				db "WriteConsoleA",0
	str_VirtualAlloc				db "VirtualAlloc",0
	str_VirtualFree					db "VirtualFree",0
	str_AdjustWindowRect			db "AdjustWindowRect",0
	str_GetDC						db "GetDC",0
	str_ReleaseDC					db "ReleaseDC",0
	str_DeleteObject				db "DeleteObject",0
	str_StretchDIBits				db "StretchDIBits",0
	str_StretchBlt					db "StretchBlt",0
	str_CreateDIBSection			db "CreateDIBSection",0
	str_BeginPaint					db "BeginPaint",0

	str_WM_EXITSIZEMOVE				db "WM_EXITSIZEMOVE",10,0
	str_WM_SIZE						db "WM_SIZE",10,0
	str_WM_ACTIVATEAPP				db "WM_ACTIVATEAPP",10,0
	str_WM_CLOSE					db "WM_CLOSE",10,0
	str_WM_DESTROY					db "WM_DESTROY",10,0
	str_WM_PAINT					db "WM_PAINT",10,0
	str_WM_GETMINMAXINFO			db "WM_GETMINMAXINFO",10,0


%endif
