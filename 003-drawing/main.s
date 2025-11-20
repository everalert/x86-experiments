; minimal windowing via win32 api
; 2025/11/16
;
; nasm -fwin32 main.s
; GoLink /entry _main main.obj user32.dll kernel32.dll
; main.exe


global _main

extern _GetModuleHandleA@4	; kernel32.dll
extern _GetStdHandle@4		; kernel32.dll
extern _AttachConsole@4		; kernel32.dll
extern _GetConsoleWindow@0	; kernel32.dll
extern _WriteConsoleA@20	; kernel32.dll
extern _ExitProcess@4		; kernel32.dll
extern _VirtualAlloc@16		; kernel32.dll
extern _VirtualFree@12		; kernel32.dll
extern _GetLastError@0		; kernel32.dll
extern _SetLastError@4		; kernel32.dll
extern _FormatMessageA@28	; kernel32.dll
extern _MessageBoxA@16		; user32.dll
extern _CreateWindowExA@48	; user32.dll
extern _ShowWindow@8		; user32.dll
extern _UpdateWindow@4		; user32.dll
extern _DestroyWindow@4		; user32.dll
extern _GetMessageA@16		; user32.dll
extern _TranslateMessage@4	; user32.dll
extern _DispatchMessageA@4	; user32.dll
extern _PostQuitMessage@4	; user32.dll
extern _DefWindowProcA@16	; user32.dll
extern _LoadImageA@24		; user32.dll
extern _RegisterClassExA@4	; user32.dll
extern _AdjustWindowRect@12	; user32.dll
extern _ValidateRect@8		; user32.dll
extern _BeginPaint@8		; user32.dll
extern _EndPaint@8			; user32.dll
extern _GetDC@4				; user32.dll
extern _ReleaseDC@8			; user32.dll
extern _StretchDIBits@52	; gdi32.dll


struc ScreenBuffer
	.Width						resd 1			; 0x00	i32
	.Height						resd 1			; 0x04	i32
	.BytesPerPixel				resd 1			; 0x08	i32
	.Pitch						resd 1			; 0x0C	i32
	.Memory						resd 1			; 0x10	void*
	.Info						resb 0x40		; 0x14	BITMAPINFOHEADER
endstruc

struc RECT
	.Lf							resd 1
	.Tp							resd 1
	.Rt							resd 1
	.Bt							resd 1
endstruc

struc PAINTSTRUCT
	.hDC						resd 1
	.fErase						resd 1
	.rcPaint					resb RECT_size
	.fRestore					resd 1
	.fIncUpdate					resd 1
	.rgbReserved				resb 32
endstruc


section .data

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
	WM_EXITSIZEMOVE					equ 0x0232
	CS_VREDRAW						equ	0x0001
	CS_HREDRAW						equ	0x0002
	WS_SHOWNORMAL					equ 1
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

	; our stuff
    str_window_name					db "TestWindow",0
	str_wndclass_name				db "TestWndClass",0
	wndclass_sz						dd 0x30
	str_newline						db 10,0
	str_error						db "Error!",0
	str_errmsg_format				db "[ERROR] (00000000) ",0		; will be filled in and expanded by fn
	strlen_errmsg_format			dd $-str_errmsg_format-1
	strloc_errmsg_format_err		dd 9							; position of the start of the error code
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


section .bss

	ModuleHandle:				resd 1
	StdHandle:					resd 1
	WindowHandle:				resd 1
	WindowMessage:				resd 1
	DeviceContextHandle:		resd 1
	WndClassEx:					resb 0x30

	BackBuffer					resb ScreenBuffer_size
 

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
	push	NULL						; lpModuleName
	call	_GetModuleHandleA@4
	mov		[ModuleHandle], eax
	cmp		eax, 0
	jnz		get_hinst_success
    push	str_GetModuleHandleA
	call	show_error_and_exit
get_hinst_success:
	push	eax							; print HINSTANCE
	call	print_u32

initialize_window_class:
	push	strlen_init_wndclass
	push	str_init_wndclass
	call	print
	push	eax
	push	ebx
	push	ecx
	mov		ecx, [ModuleHandle]
	mov		ebx, [wndclass_sz]
	mov		dword [WndClassEx+0x00], ebx					; cbSize
	mov		dword [WndClassEx+0x04], CS_HREDRAW|CS_VREDRAW	; style
	mov		dword [WndClassEx+0x08], wndproc				; lpfnWndProc
	mov		dword [WndClassEx+0x0C], 0						; cbClsExtra
	mov		dword [WndClassEx+0x10], 0						; cbWndExtra
	mov		dword [WndClassEx+0x14], ecx					; hInstance
	push	LR_DEFAULTSIZE									; fuLoad
	push	0												; cy
	push	0												; cx
	push	IMAGE_ICON										; type
	push	IDI_APPLICATION									; name
	push	ecx												; hInstance
    call	_LoadImageA@24
	push	eax												; print LoadImageA(Icon) result
	call	print_u32
	mov		dword [WndClassEx+0x18], eax					; hIcon
	mov		dword [WndClassEx+0x2C], eax					; hIconSm
	push	LR_DEFAULTSIZE									; fuLoad
	push	0												; cy
	push	0												; cx
	push	IMAGE_CURSOR									; type
	push	IDC_ARROW										; name
	push	ecx												; hInstance
    call	_LoadImageA@24
	push	eax												; print LoadImageA(Cursor) result
	call	print_u32
	mov		dword [WndClassEx+0x1C], eax					; hCursor
	mov		dword [WndClassEx+0x20], COLOR_WINDOWFRAME
	mov		dword [WndClassEx+0x24], 0						; lpszMenuName
	mov		dword [WndClassEx+0x28], str_wndclass_name		; lpszClassName
	pop		ecx
	pop		ebx
	pop		eax

register_wndclass:
	push	strlen_reg_wndclass
	push	str_reg_wndclass
	call	print
	push	WndClassEx
	call	_RegisterClassExA@4
	push	eax												; print result
	call	print_u32
	cmp		eax, 0
	jnz		register_wndclass_success
    push	str_RegisterClassExA
	call	show_error_and_exit
register_wndclass_success:

; showing window

create_window:
	push	strlen_create_window
	push	str_create_window
	call	print						; "Creating Window"
	push	ebx
	push	ecx
	sub		esp, RECT_size
	mov		ebx, esp
	mov		dword [ebx+RECT.Lf], 0
	mov		dword [ebx+RECT.Tp], 0
	mov		dword [ebx+RECT.Rt], 320
	mov		dword [ebx+RECT.Bt], 240
	push	0							;  bMenu
	push	WS_OVERLAPPEDWINDOW			;  dwStyle,
	push	ebx							;  lpRect,
	call	_AdjustWindowRect@12
	cmp		eax, 0
	jnz		create_window_adjust_rect_success
    push	str_AdjustWindowRect
	call	show_error_and_exit
create_window_adjust_rect_success:
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
	push 	WS_OVERLAPPEDWINDOW
	push 	str_window_name
	push 	str_wndclass_name
	push 	WS_EX_CLIENTEDGE
	call	_CreateWindowExA@48
	push	eax							; print HWND
	call	print_u32
	cmp		eax, 0
	jnz		create_window_success
    push	str_CreateWindowExA
	call	show_error_and_exit
create_window_success:
	add		esp, RECT_size
	pop		ecx
	pop		ebx
	mov		[WindowHandle], eax

show_window:
	push	strlen_show_window
	push	str_show_window
	call	print
	push	WS_SHOWNORMAL
	push	[WindowHandle]
	call	_ShowWindow@8

update_window:
	push	[WindowHandle]
	call	_UpdateWindow@4

msg_loop:
	push	0
	push	0
	push	0
	push	WindowMessage
	call	_GetMessageA@16				; switch to PeekMessage (non-blocking) and timed outer loop
	cmp		eax, 0
	; TODO: also handle -1 (error) case before processing messages; see GetMessage
	; on MSDN for details
	jng		done					
	push	WindowMessage
	call	_TranslateMessage@4
	push	WindowMessage
	call	_DispatchMessageA@4
	jmp		msg_loop

; end program
	
done:
	mov		ebx, [WindowMessage]
    push	[ebx+0x08]					; wParam 	
    call	_ExitProcess@4

exit:
    push	0							; no error
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
	mov		ebx, [ebp+12]				; msg
	; handle messages
wndproc_wm_paint:
	cmp		ebx, WM_PAINT
	jnz		wndproc_wm_size
	push	strlen_WM_PAINT
	push	str_WM_PAINT
	call	print
	; write a pixel to test
	mov		eax, [BackBuffer+ScreenBuffer.Memory]
	mov		dword [eax+1024*4], 0xFF000000			; FIXME: can't see this pixel after drawing!!!
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
  	push	[edx+PAINTSTRUCT.rcPaint+RECT.Bt]	; DestHeight
  	push	[edx+PAINTSTRUCT.rcPaint+RECT.Rt]	; DestWidth
  	push	[edx+PAINTSTRUCT.rcPaint+RECT.Tp]	; yDest
  	push	[edx+PAINTSTRUCT.rcPaint+RECT.Lf]	; xDest
	push	[DeviceContextHandle]				; hdc
	call	_StretchDIBits@52
	; releasedc
	push	[DeviceContextHandle]
	push	[WindowHandle]
	call	_ReleaseDC@8
	; endpaint
	mov		edx, esp
	push	edx
	push	[WindowHandle]
	call	_EndPaint@8
	; validaterect (old)
	;push	0
	;push	[WindowHandle]
	;call	_ValidateRect@8				; just to prevent spam, use BeginPaint/EndPaint if actually handling
	add		esp, PAINTSTRUCT_size
	jmp		wndproc_return_handled
wndproc_wm_size:
	cmp		ebx, WM_SIZE
	jnz		wndproc_wm_exitsizemove
	push	strlen_WM_SIZE
	push	str_WM_SIZE
	call	print
	; update buffer size
	mov		dx, word [ebp+20]
	push	edx							; height
	mov		dx, word [ebp+22]
	push	edx							; width
	push	BackBuffer
	call	set_screen_size
	jmp		wndproc_return_handled
wndproc_wm_exitsizemove:
	cmp		ebx, WM_EXITSIZEMOVE
	jnz		wndproc_wm_close
	push	strlen_WM_EXITSIZEMOVE
	push	str_WM_EXITSIZEMOVE
	call	print
	jmp		wndproc_return_handled
wndproc_wm_close:
	cmp		ebx, WM_CLOSE
	jnz		wndproc_wm_destroy
	push	strlen_WM_CLOSE
	push	str_WM_CLOSE
	call	print
	;push	[WindowHandle]
	;call	_DestroyWindow@4
	jmp		exit						; not "proper" but the only way everything disappears instantly
	jmp		wndproc_return_handled
wndproc_wm_destroy:
	cmp		ebx, WM_DESTROY
	jnz		wndproc_wm_activateapp
	push	strlen_WM_DESTROY
	push	str_WM_DESTROY
	call	print
	;push	0
	;call	_PostQuitMessage@4
	jmp		exit						; not "proper" but the only way everything disappears instantly
	jmp		wndproc_return_handled
wndproc_wm_activateapp:
	cmp		ebx, WM_ACTIVATEAPP
	jnz		wndproc_default
	push	strlen_WM_ACTIVATEAPP
	push	str_WM_ACTIVATEAPP
	call	print
	jmp		wndproc_return_handled
wndproc_default:
	mov		ecx, [ebp+20]
	push	ecx
	mov		ecx, [ebp+16]
	push	ecx
	mov		ecx, [ebp+12]
	push	ecx
	mov		ecx, [ebp+8]
	push	ecx
	call	_DefWindowProcA@16
	jmp		wndproc_return				; eax should hold return value here
	; epilogue
wndproc_return_handled:
	mov		eax, 0
wndproc_return:
	pop		edx
	pop		ecx
	pop		ebx
	pop		ebp
	ret		16

; TODO: output formatted message containing error code
;  see: GetLastError, FormatMessageA
; display error message in a messagebox and exit
; fn show_error_and_exit(message: [*:0]const u8) callconv(.stdcall) noreturn
show_error_and_exit:
	; prologue
	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	push	ecx
	sub		esp, 256					; [256]u8
	; show message
	mov		ebx, esp
	mov		ecx, esp
	push	str_errmsg_format			; src
	push	ebx							; dst
	call	strcpy
	add		ebx, [strloc_errmsg_format_err]
	call	_GetLastError@0
	push	ebx
	push	eax
	call	htoa
	mov		ebx, ecx
	add		ebx, strlen_errmsg_format
	push	[ebp+8]						; src
	push	ebx							; dst
	call	strcpy
    push	MB_OK|MB_ICONEXCLAMATION
	push	str_error
    push	ecx							; message
    push	[ModuleHandle]
    call	_MessageBoxA@16
    push	0							; no error
    call	_ExitProcess@4 
	; epilogue
	add		esp, 256
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp

; attach console and get std i/o handle
; fn init_stdio(handle: *HANDLE) callconv(.stdcall) void
init_stdio:
	; prologue
	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	; init
	mov		ebx, [ebp+8]				; *HANDLE
	push	ATTACH_PARENT_PROCESS
	call	_AttachConsole@4
	cmp		eax, 0
	jnz		init_stdio_get_handle
	cmp		eax, ERROR_ACCESS_DENIED	; already attached to console, apparently
	jnz		init_stdio_get_handle
	push	str_AttachConsole
	call	show_error_and_exit
init_stdio_get_handle:
	push	STD_OUTPUT_HANDLE
	call	_GetStdHandle@4
	mov		[ebx], eax					; output handle
	cmp		eax, INVALID_VALUE_HANDLE
	jnz		init_stdio_done
	push	str_GetStdHandle
	call	show_error_and_exit
init_stdio_done:
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
	jnz		print_success
	push	str_WriteConsoleA
	call	show_error_and_exit
	; epilogue
print_success:
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
	sub		esp, 8						; [8]u8		output buffer
	; print
	mov		ebx, [ebp+8]				; val
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
	mov		ebx, [ebp+8]				; val
	mov		eax, [ebp+12]				; out
	mov		ecx, 8						; ecx = i
htoa_loop:
	sub		ecx, 1
	mov		edx, ebx					; val
	and		edx, 0xF
	add		edx, 0x30					; edx += '0' 
	cmp		edx, 0x39
	jle		htoa_loop_out					; char < A
	add		edx, 0x07					; edx += 'A'-':'
htoa_loop_out:
	mov		byte [eax+ecx], dl			; out[i]
	shr		ebx, 4						; val >> 4
	cmp		ecx, 0
	jg		htoa_loop
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
strcpy_loop:
	mov		cl, byte [ebx]
	mov		byte [eax], cl
	inc		eax
	inc		ebx
	cmp		cl, 0
	jnz		strcpy_loop
	; epilogue
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp
	ret		8

; NOTE: expects vbuf to be zero-init'd
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
	; work
	mov		eax, [BackBuffer+ScreenBuffer.Memory]
	cmp		eax, 0
	jz		set_screen_size_free_ok
	mov		eax, [BackBuffer+ScreenBuffer.Memory]
  	push	MEM_RELEASE					; [in] DWORD  dwFreeType
  	push	0							; [in] SIZE_T dwSize,
	push	eax							; [in] LPVOID lpAddress,
	call	_VirtualFree@12
	cmp		eax, 0
	jnz		set_screen_size_free_ok
    push	str_VirtualFree
	call	show_error_and_exit
set_screen_size_free_ok:
	mov		ecx, [ebp+12]
	mov		edx, [ebp+16]
	mov		[BackBuffer+ScreenBuffer.Width], ecx
	mov		[BackBuffer+ScreenBuffer.Height], edx
	mov		[BackBuffer+ScreenBuffer.BytesPerPixel], 4
	lea		ebx, [BackBuffer+ScreenBuffer.Info]
	mov		[ebx+0x00], 0x40								;  biSize
	mov		[ebx+0x04], ecx									;  biWidth
	mov		[ebx+0x08], 0									;  biHeight
	sub		[ebx+0x08], edx									;   negative = top-down
	mov		[ebx+0x0C], 1									;  biPlanes
	mov		[ebx+0x10], 32									;  biBitCount
	mov		[ebx+0x14], BI_RGB								;  biCompression
	shl		ecx, 2											; bitmap size = Width * BytesPerPixel(4)
	mov		[BackBuffer+ScreenBuffer.Pitch], ecx
	mul		ecx, edx										; bitmap size = Width * Height * BytesPerPixel(4)
	push	PAGE_READWRITE									; flProtect
	push	MEM_COMMIT										; flAllocationType
	push	ecx												; dwSize
	push	0												; lpAddress
	call	_VirtualAlloc@16
	cmp		eax, 0
	jnz		set_screen_size_alloc_ok
    push	str_VirtualAlloc
	call	show_error_and_exit
set_screen_size_alloc_ok:
	mov		[BackBuffer+0x10], eax
	; epilogue
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp
	ret		12

