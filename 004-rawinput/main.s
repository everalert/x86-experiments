; win32 rawinput
; 2025/11/26
;
; nasm -fwin32 main.s
; GoLink /entry _main main.obj user32.dll kernel32.dll
; main.exe


; TODO: console-based error printing
; TODO: print error with error code message


global _main

%include "win32.s"
%include "string.s"


struc ScreenBuffer
	.Width							resd 1
	.Height							resd 1
	.BytesPerPixel					resd 1
	.Pitch							resd 1
	.Memory							resd 1
	.hBitmap						resd 1
	.Info							resb 0x40	; BITMAPINFOHEADER
endstruc


section .data
	
	DefaultW						equ 640
	DefaultH						equ 360

	; our stuff
	AppRunning						dd 1
    str_window_name					db "TestWindow",0
	str_wndclass_name				db "TestWndClass",0
	str_newline						db 10,0
	str_error						db "Error!",0
	str_errmsg_format				db "[ERROR] (00000000) ",0		; will be filled in and expanded by fn
	strlen_errmsg_format			equ $-str_errmsg_format-1
	strloc_errmsg_format_err		equ 9							; position of the start of the error code
	str_get_hinst					db "Getting HINSTANCE",10,0
	str_init_wndclass				db "Initializing Window Class",10,0
	str_reg_wndclass				db "Registering Window Class",10,0
	str_create_window				db "Creating Window",10,0
	str_show_window					db "Showing Window",10,0
	str_bbuf_render					db "BackBuffer Render",10,0


section .bss

	ModuleHandle:					resd 1
	StdHandle:						resd 1
	WindowHandle:					resd 1
	WindowMessage:					resd 1
	WindowClass:					resb WNDCLASSEXA_size
	WindowSize:						resb RECT_size

	BackBuffer						resb ScreenBuffer_size
	FrameCount						resd 1
 

section .text

_main:

; console init

	push	StdHandle
	call	init_stdio

; window init

get_hinstance:
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
	call	print_h32

initialize_window_class:
	push	str_init_wndclass
	call	print
	push	eax
	push	ebx
	push	ecx
	mov		ecx, [ModuleHandle]
	mov		ebx, WNDCLASSEXA_size
	mov		dword [WindowClass+WNDCLASSEXA.cbSize], ebx
	mov		dword [WindowClass+WNDCLASSEXA.style], CS_HREDRAW|CS_VREDRAW|CS_OWNDC
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
	call	print_h32
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
	call	print_h32
	mov		dword [WindowClass+WNDCLASSEXA.hCursor], eax
	mov		dword [WindowClass+WNDCLASSEXA.hbrBackground], COLOR_WINDOWFRAME
	mov		dword [WindowClass+WNDCLASSEXA.lpszMenuName], 0
	mov		dword [WindowClass+WNDCLASSEXA.lpszClassName], str_wndclass_name
	pop		ecx
	pop		ebx
	pop		eax

register_wndclass:
	push	str_reg_wndclass
	call	print
	push	WindowClass
	call	_RegisterClassExA@4
	push	eax						; print result
	call	print_h32
	cmp		eax, 0
	jnz		.success
    push	str_RegisterClassExA
	call	show_error_and_exit
.success:

; showing window

create_window:
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
	push	eax							; print HWND
	call	print_h32
	cmp		eax, 0
	jnz		.success
    push	str_CreateWindowExA
	call	show_error_and_exit
.success:
	add		esp, RECT_size
	pop		ecx
	pop		ebx
	mov		[WindowHandle], eax

; FIXME: remove white flash that appears before first frame renders; for some 
;  reason, switching from GetMessageA to PeekMessageA caused this to start
;  happening. is it because the window sleeps at the beginning? the white flash
;  is clearly shorter with a smaller sleep.
app_loop:
	;call	backbuffer_resize
	;call	vbuf_draw_test
.msg_loop:
	push	PM_REMOVE
	push	0
	push	0
	push	[WindowHandle]				; NOTE: pushing 0 ok too
	push	WindowMessage
	call	_PeekMessageA@20
	cmp		eax, 0
	jng		.msg_loop_end
	push	WindowMessage
	call	_TranslateMessage@4
	push	WindowMessage
	call	_DispatchMessageA@4
.msg_loop_end:
	cmp		[AppRunning], 0
	je		exit
	inc		dword [FrameCount]
	call	backbuffer_resize
	call	vbuf_draw_test
	; getdc
	push	[WindowHandle]
	call	_GetDC@4	
	cmp		eax, 0
	jnz		.getdc_ok
	push	str_GetDC
	call	show_error_and_exit
.getdc_ok:
	; render
	push	eax							; DC from GetDC
	call	backbuffer_render
	; releasedc
	push	eax
	push	[WindowHandle]
	call	_ReleaseDC@8
	cmp		eax, 0
	jnz		.render_ok
	push	str_ReleaseDC
	call	show_error_and_exit
.render_ok:
	;push	7							; ~143fps
	push	16							; ~60fps
	call	_Sleep@4
	jmp		.msg_loop

; end program
	
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
	push	str_WM_PAINT
	call	print
	; prep
	call	backbuffer_resize
	call	vbuf_draw_test
	; beginpaint
	sub		esp, PAINTSTRUCT_size
	mov		edx, esp
	push	edx
	push	[WindowHandle]
	call	_BeginPaint@8
	cmp		eax, 0
	jnz		.wm_paint_beginpaint_ok
	push	str_BeginPaint
	call	show_error_and_exit
	; (re)draw
.wm_paint_beginpaint_ok:
	push	eax												; DC from BeginPaint
	call	backbuffer_render
	; endpaint
	push	edx
	push	[WindowHandle]
	call	_EndPaint@8
	add		esp, PAINTSTRUCT_size
	jmp		.return_handled
.wm_size:
	push	str_WM_SIZE
	call	print
	jmp		.return_handled
.wm_exitsizemove:
	push	str_WM_EXITSIZEMOVE
	call	print
	jmp		.return_handled
.wm_close:
	push	str_WM_CLOSE
	call	print
	mov		[AppRunning], 0
	;jmp		exit					; not "proper" but the only way everything disappears instantly
	jmp		.return_handled
.wm_destroy:
	push	str_WM_DESTROY
	call	print
	mov		[AppRunning], 0
	;jmp		exit					; not "proper" but the only way everything disappears instantly
	jmp		.return_handled
.wm_activateapp:
	push	str_WM_ACTIVATEAPP
	call	print
	jmp		.return_handled
.wm_getminmaxinfo:
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

; fn backbuffer_resize() callconv(.stdcall) void
backbuffer_resize:
	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	push	ecx
	sub		esp, RECT_size
	; size
	mov		eax, esp
	push	eax
	push	[WindowHandle]
	call	_GetClientRect@8
	mov		eax, esp
	mov		ebx, dword [eax+RECT.Bt]
	mov		ecx, dword [eax+RECT.Rt]
	cmp		[WindowSize+RECT.Bt], ebx
	jnz		.resize_ok
	cmp		[WindowSize+RECT.Rt], ecx
	jnz		.resize_ok
	jmp		.resize_end
.resize_ok:
	push	ebx	
	push	ecx	
	push	BackBuffer
	call	set_screen_size
	mov		[WindowSize+RECT.Bt], ebx
	mov		[WindowSize+RECT.Rt], ecx
	; epilogue
.resize_end:
	add		esp, RECT_size
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp
	ret

; NOTE: might need to flush GDI at the top or bottom of this. apparently writing
;  to the pixel buffer can cause an error if you don't
; assumes the backbuffer is the same size as the client rect, i.e. set_screen_size
;  has already been called in response to any window size change
; fn backbuffer_render(hdc: HANDLE) callconv(.stdcall) void
backbuffer_render:
	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx									; memory dc handle
	push	ecx									; "old bitmap" handle
	; memory dc
	push	[ebp+8]
	call	_CreateCompatibleDC@4				; FIXME: error handling
	mov		ebx, eax
	push	[BackBuffer+ScreenBuffer.hBitmap]
	push	ebx
	call	_SelectObject@8						; FIXME: error handling
	mov		ecx, eax
	push	ROP_SRCCOPY							; rop
	push	[BackBuffer+ScreenBuffer.Height]	; hSrc
	push	[BackBuffer+ScreenBuffer.Width]		; wSrc
	push	0									; ySrc
	push	0									; xSrc
	push	ebx									; hdcSrc
	push	[WindowSize+RECT.Bt]				; hDest
	push	[WindowSize+RECT.Rt]				; wDest
	push	0                   				; yDest
	push	0                   				; xDest
	push	[ebp+8]								; hdcDest
	call	_StretchBlt@44						; eax <- BOOL
	cmp		eax, 0
	jne		.stretchdibits_ok					; TODO: check for GDIERROR
	push	str_StretchBlt
	call	show_error_and_exit					; WARN: might close without showing message, unsure
.stretchdibits_ok:
	push	ecx
	push	ebx
	call	_SelectObject@8						; FIXME: error handling
	push	ebx
	call	_DeleteDC@4							; FIXME: error handling
	; epilogue
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp
	ret		4

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

; print to console. use `printn` for non-null-terminated strings
; fn print(buf: [*:0]const u8) callconv(.stdcall) void
print: 
	; prologue
	push	ebp
	mov		ebp, esp
	push	eax
	push	edx
	; write to console
	lea		edx, [esp-4]
	push	[ebp+8]
	call	strlen
	push	NULL					; lpVoidReserved
	push	edx						; lpNumberOfCharsWritten
	push	eax						; nNumberOfCharsToWrite
	push	[ebp+8]					; lpBuffer
	push	[StdHandle]				; hConsoleOutput
	call	_WriteConsoleA@20
	cmp		eax, NULL
	jnz		.success
	push	str_WriteConsoleA
	call	show_error_and_exit
	; epilogue
.success:
	pop		ebx
	pop		eax
	pop		ebp
	ret		4

; print to console
; fn printn(buf: [*]const u8, len: u32) callconv(.stdcall) void
printn: 
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

; print to console with newline. use `printnln` for non-null-terminated strings
; fn println(buf: [*:0]const u8) callconv(.stdcall) void
println: 
	; prologue
	push	ebp
	mov		ebp, esp
	; write to console
	push	[ebp+8]
	call	print
	push	str_newline
	call	print
	; epilogue
.success:
	pop		ebp
	ret		4

; print to console with newline
; fn printnln(buf: [*]const u8, len: u32) callconv(.stdcall) void
printnln: 
	; prologue
	push	ebp
	mov		ebp, esp
	; write to console
	push	[ebp+12]
	push	[ebp+8]
	call	printn
	push	str_newline
	call	print
	; epilogue
.success:
	pop		ebp
	ret		8

; print decimal-formatted signed 32-bit value
; fn print_i32(val: u32) callconv(.stdcall) void
print_i32:
	; prologue
	push	ebp
	mov		ebp, esp
	push	eax
	sub		esp, 12					; [10]u8 output + padding
	; print
	mov		eax, esp
	push	eax
	push	[ebp+8]
	call	itoa
	push	11
	push	eax
	call	printnln
	; epilogue
	add		esp, 12
	pop		eax
	pop		ebp
	ret		4

; print decimal-formatted unsigned 32-bit value
; fn print_u32(val: u32) callconv(.stdcall) void
print_u32:
	; prologue
	push	ebp
	mov		ebp, esp
	push	eax
	sub		esp, 12					; [10]u8 output + padding
	; print
	mov		eax, esp
	push	eax
	push	[ebp+8]
	call	utoa
	push	10
	push	eax
	call	printnln
	; epilogue
	add		esp, 12
	pop		eax
	pop		ebp
	ret		4

; print hex-formatted 32-bit value
; fn print_h32(val: u32) callconv(.stdcall) void
print_h32:
	; prologue
	push	ebp
	mov		ebp, esp
	push	eax
	sub		esp, 8					; [8]u8		output buffer
	; print
	mov		eax, esp
	push	eax
	push	[ebp+8]
	call	htoa
	push	8
	push	eax
	call	printnln
	; epilogue
	add		esp, 8
	pop		eax
	pop		ebp
	ret		4

; print binary-formatted 32-bit value
; fn print_b32(val: u32) callconv(.stdcall) void
print_b32:
	; prologue
	push	ebp
	mov		ebp, esp
	push	eax
	sub		esp, 32					; [32]u8		output buffer
	; print
	mov		eax, esp
	push	eax
	push	[ebp+8]
	call	btoa
	push	32
	push	eax
	call	printnln
	; epilogue
	add		esp, 32
	pop		eax
	pop		ebp
	ret		4

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
	mov		eax, [BackBuffer+ScreenBuffer.hBitmap]
	cmp		eax, 0
	jz		.free_ok
	push	eax
	call	_DeleteObject@4
	cmp		eax, 0
	jnz		.free_ok
    push	str_DeleteObject
	call	show_error_and_exit
.free_ok:
	mov		[BackBuffer+ScreenBuffer.hBitmap], 0
	mov		[BackBuffer+ScreenBuffer.Memory], 0
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
	push	NULL											; offset
	push	NULL											; hSection
	push	BackBuffer+ScreenBuffer.Memory					; **ppvBits
	push	DIB_RGB_COLORS									; usage
	push	BackBuffer+ScreenBuffer.Info					; *pbmi
	push	NULL											; hdc
	call	_CreateDIBSection@24							; eax <- HBITMAP
	cmp		eax, 0
	jnz		.alloc_ok
    push	str_CreateDIBSection
	call	show_error_and_exit
.alloc_ok:
	mov		[BackBuffer+ScreenBuffer.hBitmap], eax
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
	mov		ecx, dword [FrameCount]
	and		ecx, 0x00003F
	or		ecx, 0x101000
	push	ecx
	;push	0x101010				; 0xRRGGBB
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

