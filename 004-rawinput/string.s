%ifndef	_STRING_S_
%define	_STRING_S_


; TODO: options for non-zero-padded value-to-string conversions
; - have functions return the final length of the string, including when padding
; - add bool argument for removing the padding, e.g. by stopping when there is
;   no more input left, and transferring the output from back of buffer to front


section .text

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

; FIXME: repne scas
; fn strlen(buf: [*:0]const u8) callconv(.stdcall) u32
strlen:
	push	edi
	push	ecx
	xor		eax, eax
	mov		edi, [esp+12]
	mov		ecx, 0xFFFFFFFF
	repne	scasb
	not		ecx
	dec		ecx
	mov		eax, ecx
	pop		ecx
	pop		edi
	ret		4

; convert signed 32-bit value to decimal string
; fn itoa(val: u32, out: *[11]u8) callconv(.stdcall) void
itoa:
	; prologue
	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	push	ecx
	; init
	mov		ecx, [ebp+12]
	mov		byte [ecx], 0x20		; out[0] = ' '
	mov		eax, [ebp+8]			; val
	and		eax, 0x80000000
	mov		eax, [ebp+8]			; val
	jz		.sign_ok
	xor		ebx, ebx
	sub		ebx, eax
	mov		eax, ebx
	mov		byte [ecx], 0x2D		; out[0] = '-'
.sign_ok:
	mov		ebx, ecx				; out
	inc		ebx						; start at out[1] because out[0] is the sign
	push	ebx
	push	eax
	call	utoa
	; epilogue
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp
	ret		8

; convert unsigned 32-bit value to decimal string
; fn utoa(val: u32, out: *[10]u8) callconv(.stdcall) void
utoa:
	; prologue
	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	push	ecx
	push	edx
	; init
	mov		eax, dword [ebp+8]			; val
	mov		ebx, [ebp+12]			; out
	mov		ecx, 10					; ecx = i
.loop:
	dec		ecx
	jl		.loop_end
	push	ecx
	xor		edx, edx
	mov		ecx, dword 10
	div		ecx
	pop		ecx
	add		edx, 0x30				; edx += '0' 
	mov		byte [ebx+ecx], dl		; out[i]
	jmp		.loop
.loop_end:
	; epilogue
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp
	ret		8

; convert 8-bit value to binary string
; fn btoa(val: u8, out: *[8]u8) callconv(.stdcall) void
b8toa:
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
	dec		ecx
	jl		.loop_end
	mov		edx, ebx				; val
	and		edx, 0x1
	add		edx, 0x30				; edx += '0' 
	mov		byte [eax+ecx], dl		; out[i]
	shr		ebx, 1					; val >> 1
	jmp		.loop
.loop_end:
	; epilogue
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp
	ret		8

; convert 32-bit value to binary string
; fn btoa(val: u32, out: *[32]u8) callconv(.stdcall) void
btoa:
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
	mov		ecx, 32					; ecx = i
.loop:
	dec		ecx
	jl		.loop_end
	mov		edx, ebx				; val
	and		edx, 0x1
	add		edx, 0x30				; edx += '0' 
	mov		byte [eax+ecx], dl		; out[i]
	shr		ebx, 1					; val >> 1
	jmp		.loop
.loop_end:
	; epilogue
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp
	ret		8

; convert 32-bit value to hex string
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
	dec		ecx
	jl		.loop_end
	mov		edx, ebx				; val
	and		edx, 0xF
	add		edx, 0x30				; edx += '0' 
	cmp		edx, 0x39
	jle		.loop_out				; char < A
	add		edx, 0x07				; edx += 'A'-':'
.loop_out:
	mov		byte [eax+ecx], dl		; out[i]
	shr		ebx, 4					; val >> 4
	jmp		.loop
.loop_end:
	; epilogue
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp
	ret		8


%endif
