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
extern _GetMessageA@16		; user32.dll
extern _TranslateMessage@4	; user32.dll
extern _DispatchMessageA@4	; user32.dll
extern _DefWindowProcA@16	; user32.dll
extern _LoadIconA@8			; user32.dll, NOTE: apparently superseded by LoadImageA
extern _LoadCursorA@8		; user32.dll, NOTE: apparently superseded by LoadImageA
extern _RegisterClassA@4	; user32.dll, NOTE: apparently superseded by RegisterClassEx

; %1  error message string
%macro ShowErrorMessage 1
    push	MB_OK|MB_ICONEXCLAMATION
    push	str_error
    push	%1
    push	[HINSTANCE]
    call	_MessageBoxA@16
	jmp		exit
%endmacro

; %1  string len
; %2  string
%macro WriteConsole 2
	push	eax
	push	ecx
	mov		ecx, %1
	push	ebx
	mov		ebx, %2
	push	NULL					; lpVoidReserved
	push	StdOutCharsWritten		; lpNumberOfCharsWritten
	push	ecx						; nNumberOfCharsToWrite
	push	ebx						; lpBuffer
	push	[HSTDOUT]				; hConsoleOutput
	call	_WriteConsoleA@20
	cmp		eax, NULL
	pop		ebx
	pop		ecx
	pop		eax
	jnz		%%success
	ShowErrorMessage str_err_write_console
	%%success:
%endmacro

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
	CW_USEDEFAULT				equ	0x80000000
	WS_OVERLAPPEDWINDOW			equ 0x00CF0000
	WS_EX_CLIENTEDGE			equ 0x00000200
	MB_OK						equ 0x00
	MB_ICONEXCLAMATION			equ 0x30
	; our stuff
    msg							db "SUCCESS!!!",0
    WindowName					db "CreateWindowEx test",0
	WndClassName				db "TestWndClass",0
	WndClassExSz				dd 0x30
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
	str_init_wnd_class			db "Initializing Window Class",10,0
	strlen_init_wnd_class		dd $-str_init_wnd_class
	str_reg_wnd_class			db "Registering Window Class",10,0
	strlen_reg_wnd_class		dd $-str_reg_wnd_class
	str_create_window			db "Creating Window",10,0
	strlen_create_window		dd $-str_create_window
	str_show_window				db "Showing Window",10,0
	strlen_show_window			dd $-str_show_window

section .bss
	HINSTANCE:					resd 1
	HSTDOUT:					resd 1
	HWND:						resd 1
	HWND_CONSOLE:				resd 1
	WndClassEx:					resb 0x30
	WindowMessage:				resd 1
	StdOutCharsWritten			resd 1
 
section .text

_main:

; console init

console_setup:
	push	ATTACH_PARENT_PROCESS
	call	_AttachConsole@4
	cmp		eax, 0
	jnz		console_get_handle
	ShowErrorMessage str_err_attach_console
console_get_handle:
	push	STD_OUTPUT_HANDLE
	call	_GetStdHandle@4
	mov		[HSTDOUT], eax
	cmp		eax, INVALID_VALUE_HANDLE
	jnz		console_setup_done
	ShowErrorMessage str_err_get_std_handle
console_setup_done:

;console_test_write:
;	WriteConsole [strlen_console_test], str_console_test

; testing hex to alpha
; 0x00112233 -> '0','0','1','1','2','2','3','3'
test_htoa:
	sub		esp, 12		; [8]u8		output buffer
						; u32		input value
	lea		eax, [esp+4]	; *output buffer
	lea		ebx, [esp+0]	; *input value
	mov		dword [ebx], 0x0123ABCD
conv_htoa:
	push	edx
	push	ecx
	mov		ecx, 8			; (i) input position
conv_htoa_loop:
	sub		ecx, 1
	mov		edx, [ebx]		; input value
	and		edx, 0xF
	add		edx, 0x30		; dl += '0' 
	cmp		edx, 0x39
	jle		conv_htoa_loop_output	; char < A
	add		edx, 0x07
conv_htoa_loop_output:
	mov		byte [eax+ecx], dl
	shr		dword [ebx], 4
	cmp		ecx, 0
	jge		conv_htoa_loop
	pop		ecx
	pop		edx
test_htoa_output:
	WriteConsole 8, eax
	WriteConsole 1, str_newline
	add		esp, 12
	jmp exit

; window init

get_hinstance:
	WriteConsole [strlen_get_hinst], str_get_hinst
	push	NULL						; lpModuleName
	call	_GetModuleHandleA@4
	mov		[HINSTANCE], eax
	cmp		eax, 0
	jz		wnd_hinst_error

initialize_window_class:
	WriteConsole [str_init_wnd_class], strlen_init_wnd_class
	;mov		ebx, WndClassEx
	mov		ebx, [WndClassExSz]
	mov		dword [WndClassEx+0x00], ebx					; cbSize
	;mov	dword [WndClassEx+0x04], 0						; style
	mov		dword [WndClassEx+0x08], _DefWindowProcA@16		; lpfnWndProc
	;mov	dword [WndClassEx+0x0C], 0						; cbClsExtra
	;mov	dword [WndClassEx+0x10], 0						; cbWndExtra
	mov		dword [WndClassEx+0x14], 0						; hInstance
	push	IDI_APPLICATION
	push	dword [HINSTANCE]
    call	_LoadIconA@8
	mov		dword [WndClassEx+0x18], eax					; hIcon
	mov		dword [WndClassEx+0x2C], eax					; hIconSm
	push	IDC_ARROW
	push	[HINSTANCE]
    call	_LoadCursorA@8
	mov		dword [WndClassEx+0x1C], eax					; hCursor
	mov		dword [WndClassEx+0x20], COLOR_WINDOWFRAME
	;mov	dword [WndClassEx+0x24], 0						; lpszMenuName
	mov		dword [WndClassEx+0x28], WndClassName			; lpszClassName

register_window_class:
	WriteConsole [str_reg_wnd_class], strlen_reg_wnd_class
	push	WndClassEx
	call	_RegisterClassA@4
	cmp		eax, 0
	jz		wnd_reg_error

; showing window

create_window:
	WriteConsole [str_create_window], strlen_create_window
	push	0						; lpParam 
	push 	[HINSTANCE]
	push 	0						; hMenu
	push 	0						; hWndParent
	push 	320						; nHeight
	push 	240						; nWidth
	push 	CW_USEDEFAULT			; Y
	push 	CW_USEDEFAULT			; X
	push 	WS_OVERLAPPEDWINDOW
	push 	WindowName
	push 	WndClassName
	push 	WS_EX_CLIENTEDGE
	call	_CreateWindowExA@48
	cmp		eax, 0
	jz		wnd_create_error
	mov		[HWND], eax

show_window:
	WriteConsole [str_show_window], strlen_show_window
	push	1		; WS_SHOWNORMAL
	push	[HWND]
	call	_ShowWindow@8

update_window:
	push	[HWND]
	call	_UpdateWindow@4

msg_loop:
	push	0
	push	0
	push	0
	push	WindowMessage
	call	_GetMessageA@16
	cmp		eax, 0
	jz		done
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

wnd_hinst_error:
    push	word 0x30|0x00					; MB_OK | MB_ICONEXCLAMATION
    push	dword str_error
    push	dword str_hinst_failed
    push	dword [HINSTANCE]
    call	_MessageBoxA@16
	jmp		exit

wnd_reg_error:
    push	word 0x30					; MB_OK | MB_ICONEXCLAMATION
    push	dword str_error
    push	dword str_wnd_reg_failed
    push	dword [HINSTANCE]
    call	_MessageBoxA@16
	jmp		exit

wnd_create_error:
    push	word 0x30					; MB_OK | MB_ICONEXCLAMATION
    push	dword str_error
    push	dword str_wnd_create_failed
    push	dword [HINSTANCE]
    call	_MessageBoxA@16
	jmp		exit

; stdcall
; LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
wndproc:
	add		esp, 0x10			; do nothing for now
	mov		eax, 0
