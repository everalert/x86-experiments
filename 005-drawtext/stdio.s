%ifndef	_STDIO_S_
%define	_STDIO_S_


%include "win32.s"
%include "string.s"


section .data

	str_space						db 0x20,0
	str_newline						db 10,0


section .text

; dump any print testing stuff here
; fn stdio_test() callconv(.stdcall) void
stdio_test:
	;push	RAWINPUT.data
	;call	print_h32
	;push	RAWINPUT.data.mouse
	;call	print_h32
	;push	RAWHID_size
	;call	print_u32
	ret

; attach console and get std i/o handle
; fn stdio_init(handle: *HANDLE) callconv(.stdcall) void
stdio_init:
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
	push	ecx
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
	pop		edx
	pop		ecx
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
	push	ebx
	push	ecx
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
	pop		ecx
	pop		ebx
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

; fn print_hexdump(data: [*]const u8, len: u32, row_size: u32) callconv(.stdcall) void
print_hexdump:
	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	push	ecx
	push	edx
	sub		esp, 8
	; work
	mov		eax, [ebp+12]
	add		eax, [ebp+8]
	mov		ebx, [ebp+8]
	mov		edx, esp
.data:
	cmp		ebx, eax
	jge		.data_done
	mov		ecx, [ebp+16]
.data_inner:
	dec		ecx
	jl		.data_inner_done
	push	edx
	push	[ebx]
	call	htoa
	push	8
	push	edx
	call	printn
	push	str_space
	call	print
	add		ebx, 4
	cmp		ebx, eax
	jl		.data_inner
.data_inner_done:
	push	str_newline
	call	print
	jmp		.data
.data_done:
	; epilogue
	add		esp, 8
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp
	ret		12

; fn print_bindump(data: [*]const u8, len: u32, row_size: u32) callconv(.stdcall) void
print_bindump:
	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	push	ecx
	push	edx
	sub		esp, 8
	; work
	mov		eax, [ebp+12]
	add		eax, [ebp+8]
	mov		ebx, [ebp+8]
	mov		edx, esp
.data:
	cmp		ebx, eax
	jge		.data_done
	mov		ecx, [ebp+16]
.data_inner:
	dec		ecx
	jl		.data_inner_done
	push	edx
	push	[ebx]
	call	b8toa
	push	8
	push	edx
	call	printn
	push	str_space
	call	print
	inc		ebx
	cmp		ebx, eax
	jl		.data_inner
.data_inner_done:
	push	str_newline
	call	print
	jmp		.data
.data_done:
	; epilogue
	add		esp, 8
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp
	ret		12


%endif
