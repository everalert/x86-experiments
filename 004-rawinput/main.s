; drawing some shapes in a win32 window
; 2025/11/19
;
; nasm -fwin32 main.s
; GoLink /entry _main main.obj user32.dll kernel32.dll
; main.exe


; TODO: println (and update stuff that is implicitly/manually doing println)
; TODO: itoa
; TODO: btoa


global _main

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
extern _MessageBoxA@16				; user32.dll
extern _CreateWindowExA@48			; user32.dll
extern _DestroyWindow@4				; user32.dll
extern _GetMessageA@16				; user32.dll
extern _TranslateMessage@4			; user32.dll
extern _DispatchMessageA@4			; user32.dll
extern _PostQuitMessage@4			; user32.dll
extern _DefWindowProcA@16			; user32.dll
extern _LoadImageA@24				; user32.dll
extern _RegisterClassExA@4			; user32.dll
extern _AdjustWindowRect@12			; user32.dll
extern _ValidateRect@8				; user32.dll
extern _BeginPaint@8				; user32.dll
extern _EndPaint@8					; user32.dll
extern _GetDC@4						; user32.dll
extern _ReleaseDC@8					; user32.dll
extern _GetClientRect@8				; user32.dll
extern _GetSystemMetrics@4			; user32.dll
extern _StretchDIBits@52			; gdi32.dll


struc ScreenBuffer
	.Width							resd 1
	.Height							resd 1
	.BytesPerPixel					resd 1
	.Pitch							resd 1
	.Memory							resd 1
	.Info							resb 0x40	; BITMAPINFOHEADER
endstruc

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


section .data
	
	DefaultW						equ 640
	DefaultH						equ 360

	; win32 constants
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

	; our stuff
    str_window_name					db "TestWindow",0
	str_wndclass_name				db "TestWndClass",0
	str_newline						db 10,0
	str_error						db "Error!",0
	str_errmsg_format				db "[ERROR] (00000000) ",0		; will be filled in and expanded by fn
	strlen_errmsg_format			equ $-str_errmsg_format-1
	strloc_errmsg_format_err		equ 9							; position of the start of the error code
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
	str_StretchDIBits				db "StretchDIBits",0
	str_get_hinst					db "Getting HINSTANCE",10,0
	strlen_get_hinst				equ $-str_get_hinst
	str_init_wndclass				db "Initializing Window Class",10,0
	strlen_init_wndclass			equ $-str_init_wndclass
	str_reg_wndclass				db "Registering Window Class",10,0
	strlen_reg_wndclass				equ $-str_reg_wndclass
	str_create_window				db "Creating Window",10,0
	strlen_create_window			equ $-str_create_window
	str_show_window					db "Showing Window",10,0
	strlen_show_window				equ $-str_show_window
	str_WM_EXITSIZEMOVE				db "WM_EXITSIZEMOVE",10,0
	strlen_WM_EXITSIZEMOVE			equ $-str_WM_EXITSIZEMOVE
	str_WM_SIZE						db "WM_SIZE",10,0
	strlen_WM_SIZE					equ $-str_WM_SIZE
	str_WM_ACTIVATEAPP				db "WM_ACTIVATEAPP",10,0
	strlen_WM_ACTIVATEAPP			equ $-str_WM_ACTIVATEAPP
	str_WM_CLOSE					db "WM_CLOSE",10,0
	strlen_WM_CLOSE					equ $-str_WM_CLOSE
	str_WM_DESTROY					db "WM_DESTROY",10,0
	strlen_WM_DESTROY				equ $-str_WM_DESTROY
	str_WM_PAINT					db "WM_PAINT",10,0
	strlen_WM_PAINT					equ $-str_WM_PAINT
	str_WM_GETMINMAXINFO			db "WM_GETMINMAXINFO",10,0
	strlen_WM_GETMINMAXINFO			equ $-str_WM_GETMINMAXINFO


section .bss

	ModuleHandle:					resd 1
	StdHandle:						resd 1
	DeviceContextHandle:			resd 1
	WindowHandle:					resd 1
	WindowMessage:					resd 1
	WindowClass:					resb WNDCLASSEXA_size

	BackBuffer						resb ScreenBuffer_size
 

section .text

_main:

; console init

	push	StdHandle
	call	init_stdio

; window init

get_hinstance:
	push	strlen_get_hinst
	push	str_get_hinst
	call	print
	push	NULL					; lpModuleName
	call	_GetModuleHandleA@4
	mov		[ModuleHandle], eax
	cmp		eax, 0
	jnz		.success
    push	str_GetModuleHandleA
	call	show_error_and_exit
.success:
	push	eax						; print HINSTANCE
	call	print_u32

initialize_window_class:
	push	strlen_init_wndclass
	push	str_init_wndclass
	call	print
	push	eax
	push	ebx
	push	ecx
	mov		ecx, [ModuleHandle]
	mov		ebx, WNDCLASSEXA_size
	mov		dword [WindowClass+WNDCLASSEXA.cbSize], ebx
	mov		dword [WindowClass+WNDCLASSEXA.style], CS_HREDRAW|CS_VREDRAW
	mov		dword [WindowClass+WNDCLASSEXA.lpfnWndProc], wndproc
	mov		dword [WindowClass+WNDCLASSEXA.cbClsExtra], 0
	mov		dword [WindowClass+WNDCLASSEXA.cbWndExtra], 0
	mov		dword [WindowClass+WNDCLASSEXA.hInstance], ecx
	push	LR_DEFAULTSIZE									; fuLoad
	push	0												; cy
	push	0												; cx
	push	IMAGE_ICON										; type
	push	IDI_APPLICATION									; name
	push	ecx												; hInstance
    call	_LoadImageA@24
	push	eax												; print LoadImageA(Icon) result
	call	print_u32
	mov		dword [WindowClass+WNDCLASSEXA.hIcon], eax
	mov		dword [WindowClass+WNDCLASSEXA.hIconSm], eax
	push	LR_DEFAULTSIZE									; fuLoad
	push	0												; cy
	push	0												; cx
	push	IMAGE_CURSOR									; type
	push	IDC_ARROW										; name
	push	ecx												; hInstance
    call	_LoadImageA@24
	push	eax												; print LoadImageA(Cursor) result
	call	print_u32
	mov		dword [WindowClass+WNDCLASSEXA.hCursor], eax
	mov		dword [WindowClass+WNDCLASSEXA.hbrBackground], COLOR_WINDOWFRAME
	mov		dword [WindowClass+WNDCLASSEXA.lpszMenuName], 0
	mov		dword [WindowClass+WNDCLASSEXA.lpszClassName], str_wndclass_name
	pop		ecx
	pop		ebx
	pop		eax

register_wndclass:
	push	strlen_reg_wndclass
	push	str_reg_wndclass
	call	print
	push	WindowClass
	call	_RegisterClassExA@4
	push	eax						; print result
	call	print_u32
	cmp		eax, 0
	jnz		.success
    push	str_RegisterClassExA
	call	show_error_and_exit
.success:

; showing window

create_window:
	push	strlen_create_window
	push	str_create_window
	call	print					; "Creating Window"
	push	ebx
	push	ecx
	sub		esp, RECT_size
	mov		ebx, esp
	mov		dword [ebx+RECT.Lf], 0
	mov		dword [ebx+RECT.Tp], 0
	mov		dword [ebx+RECT.Rt], DefaultW
	mov		dword [ebx+RECT.Bt], DefaultH
	push	0							;  bMenu
	push	WS_OVERLAPPEDWINDOW			;  dwStyle,
	push	ebx							;  lpRect,
	call	_AdjustWindowRect@12
	cmp		eax, 0
	jnz		.adjust_rect_success
    push	str_AdjustWindowRect
	call	show_error_and_exit
.adjust_rect_success:
	push	0							; lpParam 
	push 	[ModuleHandle]
	push 	0							; hMenu
	push 	0							; hWndParent
	mov		ecx, dword [ebx+RECT.Bt]
	sub		ecx, dword [ebx+RECT.Tp]
	push 	ecx							; nHeight
	mov		ecx, dword [ebx+RECT.Rt]
	sub		ecx, dword [ebx+RECT.Lf]
	push 	ecx							; nWidth
	push 	CW_USEDEFAULT				; Y
	push 	CW_USEDEFAULT				; X
	push 	WS_OVERLAPPEDWINDOW|WS_VISIBLE
	push 	str_window_name
	push 	str_wndclass_name
	push 	WS_EX_CLIENTEDGE
	call	_CreateWindowExA@48
	push	eax						; print HWND
	call	print_u32
	cmp		eax, 0
	jnz		.success
    push	str_CreateWindowExA
	call	show_error_and_exit
.success:
	add		esp, RECT_size
	pop		ecx
	pop		ebx
	mov		[WindowHandle], eax

msg_loop:
	push	0
	push	0
	push	0
	push	WindowMessage
	call	_GetMessageA@16			; switch to PeekMessage (non-blocking) and timed outer loop
	cmp		eax, 0
	; TODO: also handle -1 (error) case before processing messages; see GetMessage
	; on MSDN for details (not applicable to PeekMessage)
	jng		done					
	push	WindowMessage
	call	_TranslateMessage@4
	push	WindowMessage
	call	_DispatchMessageA@4
	jmp		msg_loop

; end program
	
done:
	mov		ebx, [WindowMessage]
    push	[ebx+0x08]				; wParam 	
    call	_ExitProcess@4

exit:
    push	0						; no error
    call	_ExitProcess@4 

; functions

; stdcall
; LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
wndproc:
	; prologue
	push	ebp
	mov		ebp, esp
	push	ebx
	push	ecx
	push	edx
	mov		ebx, [ebp+12]			; msg
	; handle messages
	cmp		ebx, WM_PAINT
	jz		.wm_paint
	;cmp	ebx, WM_SIZE
	;jz		.wm_size
	;cmp	ebx, WM_EXITSIZEMOVE
	;jz		.wm_exitsizemove
	cmp		ebx, WM_CLOSE
	jz		.wm_close
	cmp		ebx, WM_DESTROY
	jz		.wm_destroy
	;cmp	ebx, WM_ACTIVATEAPP
	;jz		.wm_activateapp
	cmp		ebx, WM_GETMINMAXINFO
	jz		.wm_getminmaxinfo
	jmp		.default
.wm_paint:
	push	strlen_WM_PAINT
	push	str_WM_PAINT
	call	print
	; update size
	sub		esp, RECT_size
	mov		eax, esp
	push	eax
	push	[WindowHandle]
	call	_GetClientRect@8
	mov		eax, esp
	push	dword [eax+RECT.Bt]
	push	dword [eax+RECT.Rt]
	push	BackBuffer
	call	set_screen_size
	add		esp, RECT_size
	; put some stuff in the buffer
	call	vbuf_draw_test
	; (re)draw
	sub		esp, PAINTSTRUCT_size
	mov		edx, esp
	push	edx
	push	[WindowHandle]
	call	_BeginPaint@8
	mov		edx, esp
	; getdc
	push	[WindowHandle]
	call	_GetDC@4	
	cmp		eax, 0
	jnz		.wm_paint_getdc_ok
	push	str_GetDC
	call	show_error_and_exit
.wm_paint_getdc_ok:
	mov		[DeviceContextHandle], eax
	mov		edx, esp
	; stretchdibits
  	push	ROP_SRCCOPY							; rop			
  	push	DIB_RGB_COLORS						; iUsage
  	lea		eax, [BackBuffer+ScreenBuffer.Info]
  	push	eax									; *lpbmi
  	push	[BackBuffer+ScreenBuffer.Memory]	; *lpBits
  	push	[BackBuffer+ScreenBuffer.Height]	; SrcHeight
  	push	[BackBuffer+ScreenBuffer.Width]		; SrcWidth
  	push	0									; ySrc
	push	0									; xSrc
  	mov		eax, dword [edx+PAINTSTRUCT.rcPaint+RECT.Bt]	; DestHeight
	sub		eax, dword [edx+PAINTSTRUCT.rcPaint+RECT.Tp]
	push	eax
  	mov		eax, dword [edx+PAINTSTRUCT.rcPaint+RECT.Rt]	; DestWidth
	sub		eax, dword [edx+PAINTSTRUCT.rcPaint+RECT.Lf]
	push	eax
  	push	[edx+PAINTSTRUCT.rcPaint+RECT.Tp]	; yDest
  	push	[edx+PAINTSTRUCT.rcPaint+RECT.Lf]	; xDest
	push	[DeviceContextHandle]				; hdc
	call	_StretchDIBits@52
	cmp		eax, 0							; TODO: check for GDI_ERROR 
	jg		.wm_paint_stretchdibits_ok
	push	str_StretchDIBits
	call	show_error_and_exit				; FIXME: simply crashes without showing the dialog?
.wm_paint_stretchdibits_ok:
	; releasedc
	push	[DeviceContextHandle]
	push	[WindowHandle]
	call	_ReleaseDC@8
	cmp		eax, 0
	jnz		.wm_paint_releasedc_ok
	push	str_ReleaseDC
	call	show_error_and_exit
.wm_paint_releasedc_ok:
	; endpaint
	mov		edx, esp
	push	edx
	push	[WindowHandle]
	call	_EndPaint@8
	add		esp, PAINTSTRUCT_size
	jmp		.return_handled
.wm_size:
	push	strlen_WM_SIZE
	push	str_WM_SIZE
	call	print
	jmp		.return_handled
.wm_exitsizemove:
	push	strlen_WM_EXITSIZEMOVE
	push	str_WM_EXITSIZEMOVE
	call	print
	jmp		.return_handled
.wm_close:
	push	strlen_WM_CLOSE
	push	str_WM_CLOSE
	call	print
	jmp		exit					; not "proper" but the only way everything disappears instantly
	jmp		.return_handled
.wm_destroy:
	push	strlen_WM_DESTROY
	push	str_WM_DESTROY
	call	print
	jmp		exit					; not "proper" but the only way everything disappears instantly
	jmp		.return_handled
.wm_activateapp:
	push	strlen_WM_ACTIVATEAPP
	push	str_WM_ACTIVATEAPP
	call	print
	jmp		.return_handled
.wm_getminmaxinfo:
	push	strlen_WM_GETMINMAXINFO
	push	str_WM_GETMINMAXINFO
	call	print
	mov		ecx, [ebp+20]			; *MINMAXINFO
	add		[ecx+MINMAXINFO.ptMinTrackSize+POINT.x], 16
	add		[ecx+MINMAXINFO.ptMinTrackSize+POINT.y], 16
	jmp		.return_handled
.default:
	mov		ecx, [ebp+20]
	push	ecx
	mov		ecx, [ebp+16]
	push	ecx
	mov		ecx, [ebp+12]
	push	ecx
	mov		ecx, [ebp+8]
	push	ecx
	call	_DefWindowProcA@16
	jmp		.return					; eax should hold return value here
	; epilogue
.return_handled:
	mov		eax, 0
.return:
	pop		edx
	pop		ecx
	pop		ebx
	pop		ebp
	ret		16

; TODO: output formatted message containing error code
;  see: GetLastError, FormatMessageA
; display error message with error code in a messagebox and exit
; fn show_error_and_exit(message: [*:0]const u8) callconv(.stdcall) noreturn
show_error_and_exit:
	; prologue
	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	push	ecx
	sub		esp, 256				; [256]u8
	; show message
	mov		ebx, esp
	mov		ecx, esp
	push	str_errmsg_format		; src
	push	ebx						; dst
	call	strcpy
	add		ebx, strloc_errmsg_format_err
	call	_GetLastError@0
	push	ebx
	push	eax
	call	htoa
	mov		ebx, ecx
	add		ebx, strlen_errmsg_format
	push	[ebp+8]					; src
	push	ebx						; dst
	call	strcpy
    push	MB_OK|MB_ICONEXCLAMATION
	push	str_error
    push	ecx						; message
    push	[ModuleHandle]
    call	_MessageBoxA@16
    push	0						; no error
    call	_ExitProcess@4 
	; epilogue
	add		esp, 256
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp
	ret		4

; attach console and get std i/o handle
; fn init_stdio(handle: *HANDLE) callconv(.stdcall) void
init_stdio:
	; prologue
	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	; init
	mov		ebx, [ebp+8]			; *HANDLE
	push	ATTACH_PARENT_PROCESS
	call	_AttachConsole@4
	cmp		eax, 0
	jnz		.get_handle
	cmp		eax, ERROR_ACCESS_DENIED	; already attached to console, apparently
	jnz		.get_handle
	push	str_AttachConsole
	call	show_error_and_exit
.get_handle:
	push	STD_OUTPUT_HANDLE
	call	_GetStdHandle@4
	mov		[ebx], eax				; output handle
	cmp		eax, INVALID_VALUE_HANDLE
	jnz		.done
	push	str_GetStdHandle
	call	show_error_and_exit
.done:
	; epilogue
	pop		ebx
	pop		eax
	pop		ebp
	ret		4

; print to console
; fn print(buf: [*]const u8, len: u32) callconv(.stdcall) void
print: 
	; prologue
	push	ebp
	mov		ebp, esp
	push	eax
	push	ecx
	push	ebx
	push	edx
	sub		esp, 4
	; write to console
	lea		edx, [esp]
	mov		ecx, [ebp+12]			; len
	mov		ebx, [ebp+8]			; buf
	push	NULL					; lpVoidReserved
	push	edx						; lpNumberOfCharsWritten
	push	ecx						; nNumberOfCharsToWrite
	push	ebx						; lpBuffer
	push	[StdHandle]				; hConsoleOutput
	call	_WriteConsoleA@20
	cmp		eax, NULL
	jnz		.success
	push	str_WriteConsoleA
	call	show_error_and_exit
	; epilogue
.success:
	add		esp, 4
	pop		edx
	pop		ebx
	pop		ecx
	pop		eax
	pop		ebp
	ret		8

; fn print_u32(val: u32) callconv(.stdcall) void
print_u32:
	; prologue
	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	sub		esp, 8					; [8]u8		output buffer
	; print
	mov		ebx, [ebp+8]			; val
	lea		eax, [esp]
	push	eax
	push	ebx
	call	htoa
	push	8
	push	eax
	call	print
	push	1
	push	str_newline
	call	print
	; epilogue
	add		esp, 8
	pop		ebx
	pop		eax
	pop		ebp
	ret		4

; convert 4-byte u32 value to hex string
; fn htoa(val: u32, out: *[8]u8) callconv(.stdcall) void
htoa:
	; prologue
	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	push	ecx
	push	edx
	; init
	mov		ebx, [ebp+8]			; val
	mov		eax, [ebp+12]			; out
	mov		ecx, 8					; ecx = i
.loop:
	sub		ecx, 1
	mov		edx, ebx				; val
	and		edx, 0xF
	add		edx, 0x30				; edx += '0' 
	cmp		edx, 0x39
	jle		.loop_out				; char < A
	add		edx, 0x07				; edx += 'A'-':'
.loop_out:
	mov		byte [eax+ecx], dl		; out[i]
	shr		ebx, 4					; val >> 4
	cmp		ecx, 0
	jg		.loop
	; epilogue
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp
	; NOTE: not sure why the following crashes
	;  add esp, 8
	;  ret
	ret		8

; fn strcpy(dst: [*]u8, src: [*:0]const u8) callconv(.stdcall) void
strcpy:
	; prologue
	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	push	ecx
	; copy
	mov		eax, [ebp+8]
	mov		ebx, [ebp+12]
	mov		cl, 0
.loop:
	mov		cl, byte [ebx]
	mov		byte [eax], cl
	inc		eax
	inc		ebx
	cmp		cl, 0
	jnz		.loop
	; epilogue
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp
	ret		8

; NOTE: expects vbuf to be zero-init'd
; TODO: maybe floodfill black by default in set_screen_size to clear screen?
; update screen buffer resource for use in WM_SIZE etc.
; fn set_screen_size(vbuf: *ScreenBuffer, w: i32, h: i32) callconv(.stdcall) void
set_screen_size:
	; prologue
	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	push	ecx
	push	edx
	; free existing memory if needed
	mov		eax, [BackBuffer+ScreenBuffer.Memory]
	cmp		eax, 0
	jz		.free_ok
	mov		eax, [BackBuffer+ScreenBuffer.Memory]
  	push	MEM_RELEASE				; dwFreeType
  	push	0						; dwSize,
	push	eax						; lpAddress,
	call	_VirtualFree@12
	cmp		eax, 0
	jnz		.free_ok
    push	str_VirtualFree
	call	show_error_and_exit
.free_ok:
	; fill in the buffer info and alloc new memory
	mov		ecx, [ebp+12]
	mov		edx, [ebp+16]
	mov		dword [BackBuffer+ScreenBuffer.Width], ecx
	mov		dword [BackBuffer+ScreenBuffer.Height], edx
	mov		dword [BackBuffer+ScreenBuffer.BytesPerPixel], 4
	lea		ebx, [BackBuffer+ScreenBuffer.Info]
	mov		dword [ebx+BITMAPINFOHEADER.biSize], BITMAPINFOHEADER_size
	mov		dword [ebx+BITMAPINFOHEADER.biWidth], ecx
	mov		dword [ebx+BITMAPINFOHEADER.biHeight], 0
	sub		dword [ebx+BITMAPINFOHEADER.biHeight], edx
	mov		word [ebx+BITMAPINFOHEADER.biPlanes], 1
	mov		word [ebx+BITMAPINFOHEADER.biBitCount], 32
	mov		dword [ebx+BITMAPINFOHEADER.biCompression], BI_RGB
	shl		ecx, 2											; bitmap size = Width * BytesPerPixel(4)
	mov		dword [BackBuffer+ScreenBuffer.Pitch], ecx
	mul		ecx, edx										; bitmap size = Width * Height * BytesPerPixel(4)
	push	PAGE_READWRITE									; flProtect
	push	MEM_COMMIT										; flAllocationType
	push	ecx												; dwSize
	push	0												; lpAddress
	call	_VirtualAlloc@16
	cmp		eax, 0
	jnz		.alloc_ok
    push	str_VirtualAlloc
	call	show_error_and_exit
.alloc_ok:
	mov		[BackBuffer+ScreenBuffer.Memory], eax
	; epilogue
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp
	ret		12

; fn vbuf_draw_test() callconv(.stdcall) void
vbuf_draw_test:
	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	push	ecx
	push	edx
	sub		esp, 8
	; draw
	mov		eax, [BackBuffer+ScreenBuffer.Width]
	shr		eax, 2
	mov		[esp+0], eax
	mov		eax, [BackBuffer+ScreenBuffer.Height]
	shr		eax, 1
	mov		[esp+4], eax
	; clear
	push	0x101010				; 0xRRGGBB
	call	vbuf_flood			
	; circle
	mov		ecx, [esp+0]
	add		ecx, 20
	mov		edx, [esp+4]
	push	40
	push	edx
	push	ecx
	push	0xFF0000
	call	vbuf_draw_circle
	; rect
	add		ecx, [esp+0]
	sub		ecx, 40
	sub		edx, 20
	push	40
	push	40
	push	edx
	push	ecx
	push	0x00FF00
	call	vbuf_draw_rect
	; tri
	add		ecx, [esp+0]
	add		ecx, 10
	push	edx
	push	ecx
	add		ecx, 10
	add		edx, 39
	push	edx
	push	ecx
	sub		ecx, 39
	push	edx
	push	ecx
	push	0x0000FF
	call	vbuf_draw_tri
	; dots
	push	16
	push	16
	push	0xFF0000
	call	vbuf_draw_pixel
	push	16
	push	32
	push	0x00FF00
	call	vbuf_draw_pixel
	push	16
	push	48
	push	0x0000FF
	call	vbuf_draw_pixel
	push	16
	push	64
	push	0xFFFFFF
	call	vbuf_draw_pixel
	mov		edx, [BackBuffer+ScreenBuffer.Height]
	sub		edx, 16
	mov		ecx, [BackBuffer+ScreenBuffer.Width]
	sub		ecx, 16
	push	edx
	push	ecx
	push	0xFF0000
	call	vbuf_draw_pixel
	sub		ecx, 16
	push	edx
	push	ecx
	push	0x00FF00
	call	vbuf_draw_pixel
	sub		ecx, 16
	push	edx
	push	ecx
	push	0x0000FF
	call	vbuf_draw_pixel
	sub		ecx, 16
	push	edx
	push	ecx
	push	0xFFFFFF
	call	vbuf_draw_pixel
	; epilogue
	add		esp, 8
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp
	ret

; fn vbuf_flood(color: u32) callconv(.stdcall) void
vbuf_flood:
	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	push	ecx
	; flood
	mov		ecx, [ebp+8]
	mov		ebx, [BackBuffer+ScreenBuffer.Height]
	mul		ebx, [BackBuffer+ScreenBuffer.Width]
	shl		ebx, 2											; bitmap size = Width * BytesPerPixel(4)
	mov		eax, [BackBuffer+ScreenBuffer.Memory]
.loop:
	mov		dword [eax], ecx
	add		eax, 4
	sub		ebx, 4
	cmp		ebx, 0
	jnz		.loop
	; epilogue
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp
	ret		4

; fn vbuf_draw_pixel(color: u32, x: u32, y: u32) callconv(.stdcall) void
vbuf_draw_pixel:
	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	push	ecx
	; write
	mov		ecx, [ebp+12]
	cmp		ecx, 0
	jl		.return
	cmp		ecx, [BackBuffer+ScreenBuffer.Width]
	jge		.return
	mov		ebx, [ebp+16]
	cmp		ebx, 0
	jl		.return
	cmp		ebx, [BackBuffer+ScreenBuffer.Height]
	jge		.return
	mul		ebx, [BackBuffer+ScreenBuffer.Pitch]	; post-process only when early exits exhausted
	shl		ecx, 2
	add		ebx, ecx
	mov		ecx, [ebp+8]
	mov		eax, [BackBuffer+ScreenBuffer.Memory]
	mov		dword [eax+ebx], ecx
	; epilogue
.return:
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp
	ret		12

; fn vbuf_draw_line(color: u32, x1: i32, y1: i32, x2: i32, y2: i32) callconv(.stdcall) void
vbuf_draw_line:
	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	push	ecx
	push	edx
	; draw
	mov		edx, [ebp+8]			; color
	mov		ebx, [ebp+16]
	cmp		ebx, [ebp+24]
	jz		.hor
	mov		eax, [ebp+12]
	cmp		eax, [ebp+20]
	jz		.ver
; http://members.chello.at/~easyfilter/bresenham.html
.slope:
	; eax = x1, ebx = y1
	sub		esp, 20					; 00 = dx
									; 04 = dy
									; 08 = sx
									; 12 = sy
									; 16 = e
	mov		dword [esp+8], 1
	mov		dword [esp+12], -1
.slope_init_x:
	mov		ecx, [ebp+20]
	sub		ecx, eax
	jg		.slope_init_x_end		; if x2 > x1
	mov		dword [esp+8], -1
	mul		ecx, -1
.slope_init_x_end:
	mov		dword [esp+0], ecx
	mov		dword [esp+16], ecx		; e = dx
.slope_init_y:
	mov		edx, [ebp+24]
	sub		edx, ebx
	jl		.slope_init_y_end		; if y2 > y1
	mov		dword [esp+12], 1
	mul		edx, -1
.slope_init_y_end:
	mov		dword [esp+4], edx
	add		dword [esp+16], edx		; e += dy
.slope_loop:
	push	ebx
	push	eax
	push	dword [ebp+8]
	call	vbuf_draw_pixel
	cmp		eax, [ebp+20]
	jne		.slope_adjust
	cmp		ebx, [ebp+24]
	jne		.slope_adjust
	add		esp, 20
	jmp		.return
.slope_adjust:
	mov		ecx, [esp+16]			; ecx = 2e
	shl		ecx, 1					; could shift out of negative, but shouldn't in normal usage
.slope_adjust_x:
	mov		edx, [esp+4]
	cmp		ecx, edx
	jl		.slope_adjust_y			; if 2e >= dy
	add		[esp+16], edx
	add		eax, [esp+8]
.slope_adjust_y:
	mov		edx, [esp+0]
	cmp		ecx, edx
	jg		.slope_adjust_end		; if 2e <= dx
	add		[esp+16], edx
	add		ebx, [esp+12]
.slope_adjust_end:
	jmp		.slope_loop
.hor:
	; ebx = y1
	mov		eax, [ebp+12]			; x1
	mov		ecx, [ebp+20]			; x2
	cmp		eax, ecx
	jle		.hor_loop
	xor		eax, ecx
	xor		ecx, eax
	xor		eax, ecx
.hor_loop:
	push	ebx
	push	eax
	push	edx
	call	vbuf_draw_pixel
	inc		eax
	cmp		eax, ecx
	jle		.hor_loop
	jmp		.return
.ver:
	; eax = x1, ebx = y1
	mov		ecx, [ebp+24]			; y2
	cmp		ebx, ecx
	jle		.ver_loop
	xor		ebx, ecx
	xor		ecx, ebx
	xor		ebx, ecx
.ver_loop:
	push	ebx
	push	eax
	push	edx
	call	vbuf_draw_pixel
	inc		ebx
	cmp		ebx, ecx
	jle		.ver_loop
	jmp		.return
.return:
	; epilogue
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp
	ret		20

; https://www.youtube.com/watch?v=JtgQJT08J1g
; fn vbuf_draw_circle(color: u32, x: i32, y: i32, dia: u32) callconv(.stdcall) void
vbuf_draw_circle:
	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	push	ecx
	push	edx
	sub		esp, 32					; 00 = x-base for pos side
									; 04 = y-base for pos side
									; 08 = x-base for neg side
									; 12 = y-base for neg side
									; 16 = R2
									; 20 = dY
									; 24 = dX
									; 28 = D
	; circle
	mov		eax, [ebp+12]			; x
	mov		[esp+0], eax
	mov		[esp+8], eax
	mov		eax, [ebp+16]			; y
	mov		[esp+4], eax
	mov		[esp+12], eax
	shr		dword [ebp+20], 1		; dia -> rad
	jc		.center_done
	dec		dword [esp+0]			; offset pos-side center if skipping "middle" pixels (even diameter)
	dec		dword [esp+4]
.center_done:
	mov		eax, [ebp+20]			; X = rad
	shl		dword [ebp+20], 1
	mov		ebx, [ebp+20]
	mov		[esp+16], ebx			; R2
	mov		dword [esp+20], -2		; dY
	mov		[esp+24], ebx			; dX
	add		[esp+24], ebx
	sub		dword [esp+24], 4
	mov		[esp+28], ebx			; D
	dec		dword [esp+28]
	xor		ebx, ebx				; Y = 0
	mov		edx, [ebp+8]			; color
	push	ebp
	mov		ebp, esp
	add		ebp, 4
	mov		ecx, [ebp+0]
	cmp		ecx, [ebp+8]
	jne		.loop_draw_end
.loop:
	; draw iteration
	mov		ecx, [ebp+12]
	sub		ecx, eax
	push	ecx
	mov		ecx, [ebp+8]
	sub		ecx, ebx
	push	ecx
	push	edx
	call	vbuf_draw_pixel			; -Y, -X
	mov		ecx, [ebp+12]
	sub		ecx, ebx
	push	ecx
	mov		ecx, [ebp+8]
	sub		ecx, eax
	push	ecx
	push	edx
	call	vbuf_draw_pixel			; -X, -Y
	mov		ecx, [ebp+4]
	add		ecx, eax
	push	ecx
	mov		ecx, [ebp+8]
	sub		ecx, ebx
	push	ecx
	push	edx
	call	vbuf_draw_pixel			; -Y, +X
	mov		ecx, [ebp+4]
	add		ecx, ebx
	push	ecx
	mov		ecx, [ebp+8]
	sub		ecx, eax
	push	ecx
	push	edx
	call	vbuf_draw_pixel			; -X, +Y
	mov		ecx, [ebp+12]
	sub		ecx, eax
	push	ecx
	mov		ecx, [ebp+0]
	add		ecx, ebx
	push	ecx
	push	edx
	call	vbuf_draw_pixel			; +Y, -X
	mov		ecx, [ebp+12]
	sub		ecx, ebx
	push	ecx
	mov		ecx, [ebp+0]			; same as prev because stack pushed
	add		ecx, eax
	push	ecx
	push	edx
	call	vbuf_draw_pixel			; +X, -Y
	mov		ecx, [ebp+4]
	add		ecx, eax
	push	ecx
	mov		ecx, [ebp+0]			; same as prev because stack pushed
	add		ecx, ebx
	push	ecx
	push	edx
	call	vbuf_draw_pixel			; +Y, +X
	mov		ecx, [ebp+4]
	add		ecx, ebx
	push	ecx
	mov		ecx, [ebp+0]			; same as prev because stack pushed
	add		ecx, eax
	push	ecx
	push	edx
	call	vbuf_draw_pixel			; +X, +Y
.loop_draw_end:
	; calculate new x, y
	mov		ecx, [ebp+20]			; dY
	add		[ebp+28], ecx			; D += dY
	sub		dword [ebp+20], 4		; dY -= 4
	inc		ebx						; Y++
	cmp		dword [ebp+28], 0
	jge		.dec_x_done
	mov		ecx, [ebp+24]			; dX
	add		[ebp+28], ecx			; D += dX
	sub		dword [ebp+24], 4		; dX -= 4
	dec		eax						; X--
.dec_x_done:
	cmp		ebx, eax
	jle		.loop					; Y <= X
.return:
	pop		ebp
	; epilogue
	add		esp, 32
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp
	ret		16

; fn vbuf_draw_rect(color: u32, x: i32, y: i32, w: i32, h: i32) callconv(.stdcall) void
vbuf_draw_rect:
	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	push	ecx
	push	edx
	; draw
	mov		eax, [ebp+16]
	xor		ecx, ecx				; ecx = j (y)
.loop_y:
	mov		edx, [ebp+12]
	xor		ebx, ebx				; ebx = i (x)
.loop_x:
	push	eax
	push	edx
	push	[ebp+8]
	call	vbuf_draw_pixel
	inc		ecx
	cmp		ebx, 0
	jg		.loop_x_end				; don't need to check for middle at this point
	cmp		ecx, 1
	je		.loop_x_end
	cmp		ecx, [ebp+24]
	je		.loop_x_end
	add		edx, [ebp+20]			; skip the middle pixels if not 1st/last row
	sub		edx, 2
	add		ebx, [ebp+20]
	sub		ebx, 2
.loop_x_end:
	dec		ecx
	inc		edx
	inc		ebx
	cmp		ebx, [ebp+20]
	jge		.loop_y_end
	jmp		.loop_x
.loop_y_end:
	inc		eax
	inc		ecx
	cmp		ecx, [ebp+24]
	jge		.return
	jmp		.loop_y
	; epilogue
.return:
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp
	ret		20

; fn vbuf_draw_rect_fill(color: u32, x: i32, y: i32, w: i32, h: i32) callconv(.stdcall) void
vbuf_draw_rect_fill:
	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	push	ecx
	push	edx
	; draw
	mov		eax, [ebp+16]
	xor		ecx, ecx				; ecx = j (y)
.loop_y:
	mov		edx, [ebp+12]
	xor		ebx, ebx				; ebx = i (x)
.loop_x:
	push	eax
	push	edx
	push	[ebp+8]
	call	vbuf_draw_pixel
	inc		edx
	inc		ebx
	cmp		ebx, [ebp+20]
	jge		.loop_y_end
	jmp		.loop_x
.loop_y_end:
	inc		eax
	inc		ecx
	cmp		ecx, [ebp+24]
	jge		.return
	jmp		.loop_y
	; epilogue
.return:
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp
	ret		20

; fn vbuf_draw_tri(color: u32, x1: i32, y1: i32, x2: i32, y2: i32, x3: i32, y3: i32) callconv(.stdcall) void
vbuf_draw_tri:
	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	push	edx
	; draw
	mov		edx, [ebp+8]
	mov		eax, [ebp+12]
	mov		ebx, [ebp+16]
	push	ebx
	push	eax
	push	ebx
	push	eax
	mov		eax, [ebp+20]
	mov		ebx, [ebp+24]
	push	ebx
	push	eax
	push	edx
	call	vbuf_draw_line
	push	ebx
	push	eax
	mov		eax, [ebp+28]
	mov		ebx, [ebp+32]
	push	ebx
	push	eax
	push	edx
	call	vbuf_draw_line
	push	ebx
	push	eax
	push	edx
	call	vbuf_draw_line
	; epilogue
	pop		edx
	pop		ebx
	pop		eax
	pop		ebp
	ret		28


