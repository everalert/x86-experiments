; minimal windowing via win32 api
; 2025/11/16
;
; nasm -fwin32 main.s
; GoLink /entry _main main.obj user32.dll kernel32.dll
; main.exe


extern _GetModuleHandleA@4	; kernel32.dll
extern _GetStdHandle@4		; kernel32.dll
extern _AttachConsole@4		; kernel32.dll
extern _GetConsoleWindow@0	; kernel32.dll
extern _WriteConsoleA@20	; kernel32.dll
extern _ExitProcess@4		; kernel32.dll
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

global _main

section .data

	; win32 constants
	NULL						equ 0
	ATTACH_PARENT_PROCESS		equ -1
	INVALID_VALUE_HANDLE		equ -1
	STD_OUTPUT_HANDLE			equ -11
	IDI_APPLICATION				equ 0x7F00
	IDC_ARROW					equ 0x7F00
	COLOR_WINDOWFRAME			equ 6
	LR_DEFAULTSIZE				equ 0x00000040
	CW_USEDEFAULT				equ	0x80000000
	WM_DESTROY					equ 0x0002
	WM_SIZE						equ 0x0005
	WM_CLOSE					equ 0x0010
	WM_ACTIVATEAPP				equ 0x001C
	WM_EXITSIZEMOVE				equ 0x0232
	CS_HREDRAW					equ	0x0002
	CS_VREDRAW					equ	0x0001
	WS_SHOWNORMAL				equ 1
	WS_OVERLAPPEDWINDOW			equ 0x00CF0000
	WS_EX_CLIENTEDGE			equ 0x00000200
	MB_OK						equ 0x00
	MB_ICONEXCLAMATION			equ 0x30
	IMAGE_BITMAP				equ 0 ; C:\Program Files (x86)\Windows Kits\10\Include\10.0.19041.0\um\winuser.h
	IMAGE_ICON					equ 1
	IMAGE_CURSOR				equ 2

	; our stuff
    msg							db "SUCCESS!!!",0
    str_window_name				db "CreateWindowEx test",0
	str_wndclass_name			db "TestWndClass",0
	wndclass_sz					dd 0x30
	str_newline					db 10,0
	str_error					db "Error!",0
	str_wnd_reg_failed			db "Window Registration Failed!",0
	str_wnd_create_failed		db "Window Creation Failed!",0
	str_hinst_failed			db "GetModuleHandleA Failed!",0
	str_err_attach_console		db "AttachConsole Failed!",0
	str_err_get_std_handle		db "GetStdHandle Failed!",0
	str_err_get_console_window	db "GetConsoleWindow Failed!",0
	str_err_write_console		db "WriteConsoleA Failed!",0
	str_console_test			db "Console Output Test",10,0
	strlen_console_test			dd $-str_console_test
	str_get_hinst				db "Getting HINSTANCE",10,0
	strlen_get_hinst			dd $-str_get_hinst
	str_init_wndclass			db "Initializing Window Class",10,0
	strlen_init_wndclass		dd $-str_init_wndclass
	str_reg_wndclass			db "Registering Window Class",10,0
	strlen_reg_wndclass			dd $-str_reg_wndclass
	str_create_window			db "Creating Window",10,0
	strlen_create_window		dd $-str_create_window
	str_show_window				db "Showing Window",10,0
	strlen_show_window			dd $-str_show_window
	str_wm_exitsizemove			db "WM_EXITSIZEMOVE",10,0
	strlen_wm_exitsizemove		dd $-str_wm_exitsizemove
	str_wm_size					db "WM_SIZE",10,0
	strlen_wm_size				dd $-str_wm_size
	str_wm_activateapp			db "WM_ACTIVATEAPP",10,0
	strlen_wm_activateapp		dd $-str_wm_activateapp
	str_wm_close				db "WM_CLOSE",10,0
	strlen_wm_close				dd $-str_wm_close
	str_wm_destroy				db "WM_DESTROY",10,0
	strlen_wm_destroy			dd $-str_wm_destroy

section .bss

	ModuleHandle:				resd 1
	StdHandle:					resd 1
	WindowHandle:				resd 1
	WindowMessage:				resd 1
	WndClassEx:					resb 0x30
 
section .text

_main:

; console init

	push	StdHandle
	call	init_stdio

; window init

get_hinstance:
	push	[strlen_get_hinst]
	push	str_get_hinst
	call	print
	push	NULL						; lpModuleName
	call	_GetModuleHandleA@4
	mov		[ModuleHandle], eax
	cmp		eax, 0
	jnz		get_hinst_success
    push	str_hinst_failed
	call	show_error_and_exit
get_hinst_success:
	push	eax							; print HINSTANCE
	call	print_u32

initialize_window_class:
	push	[strlen_init_wndclass]
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
	push	[strlen_reg_wndclass]
	push	str_reg_wndclass
	call	print
	push	WndClassEx
	call	_RegisterClassExA@4
	push	eax												; print result
	call	print_u32
	cmp		eax, 0
	jnz		register_wndclass_success
    push	str_wnd_reg_failed
	call	show_error_and_exit
register_wndclass_success:

; showing window

create_window:
	push	[strlen_create_window]
	push	str_create_window
	call	print						; "Creating Window"
	push	0							; lpParam 
	push 	[ModuleHandle]
	push 	0							; hMenu
	push 	0							; hWndParent
	push 	240							; nHeight
	push 	320							; nWidth
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
    push	str_wnd_create_failed
	call	show_error_and_exit
create_window_success:
	mov		[WindowHandle], eax

show_window:
	push	[strlen_show_window]
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
	call	_GetMessageA@16
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
	mov		ebx, [ebp+12]				; msg
	; handle messages
wndproc_wm_size:
	cmp		ebx, WM_SIZE
	jnz		wndproc_wm_exitsizemove
	push	[strlen_wm_size]
	push	str_wm_size
	call	print
	jmp		wndproc_return_handled
wndproc_wm_exitsizemove:
	cmp		ebx, WM_EXITSIZEMOVE
	jnz		wndproc_wm_close
	push	[strlen_wm_exitsizemove]
	push	str_wm_exitsizemove
	call	print
	jmp		wndproc_return_handled
wndproc_wm_close:
	cmp		ebx, WM_CLOSE
	jnz		wndproc_wm_destroy
	push	[strlen_wm_close]
	push	str_wm_close
	call	print
	;push	[WindowHandle]
	;call	_DestroyWindow@4
	jmp		exit						; not "proper" but the only way everything disappears instantly
	jmp		wndproc_return_handled
wndproc_wm_destroy:
	cmp		ebx, WM_DESTROY
	jnz		wndproc_wm_activateapp
	push	[strlen_wm_destroy]
	push	str_wm_destroy
	call	print
	;push	0
	;call	_PostQuitMessage@4
	jmp		exit						; not "proper" but the only way everything disappears instantly
	jmp		wndproc_return_handled
wndproc_wm_activateapp:
	cmp		ebx, WM_ACTIVATEAPP
	jnz		wndproc_default
	push	[strlen_wm_activateapp]
	push	str_wm_activateapp
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
	pop		ecx
	pop		ebx
	pop		ebp
	ret		16

; display error message in a messagebox and exit
; fn show_error_and_exit(message: [*:0]const u8) callconv(.stdcall) void
show_error_and_exit:
	; prologue
	push	ebp
	mov		ebp, esp
	push	eax
	; show error
	mov		eax, [ebp+8]				; message
    push	MB_OK|MB_ICONEXCLAMATION
    push	str_error
    push	eax
    push	[ModuleHandle]
    call	_MessageBoxA@16
	; epilogue
	pop		eax
	pop		ebp
	add		esp, 8
	;ret		8
	jmp		exit

; attach console and get std i/o handle
; fn init_std(handle: *HANDLE) callconv(.stdcall) void
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
	push	str_err_attach_console
	call	show_error_and_exit
init_stdio_get_handle:
	push	STD_OUTPUT_HANDLE
	call	_GetStdHandle@4
	mov		[ebx], eax					; output handle
	cmp		eax, INVALID_VALUE_HANDLE
	jnz		init_stdio_done
	push	str_err_get_std_handle
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
	push	str_err_write_console
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
htoa_it:
	sub		ecx, 1
	mov		edx, ebx					; val
	and		edx, 0xF
	add		edx, 0x30					; edx += '0' 
	cmp		edx, 0x39
	jle		htoa_it_out					; char < A
	add		edx, 0x07					; edx += 'A'-':'
htoa_it_out:
	mov		byte [eax+ecx], dl			; out[i]
	shr		ebx, 4						; val >> 4
	cmp		ecx, 0
	jge		htoa_it
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
