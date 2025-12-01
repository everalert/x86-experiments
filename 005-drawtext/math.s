%ifndef	_MATH_S_
%define	_MATH_S_


section .data
	
	f32_0							dd 0.0
	f32_1							dd 1.0
	f64_0							dq 0.0
	f64_1							dq 1.0

	f32_pi							dd 3.14159265358979323846
	f32_tau							dd 6.28318530717958647692
	f64_pi							dq 3.14159265358979323846
	f64_tau							dq 6.28318530717958647692


section .text

; @p		phase
; @a		amplitude
; @f		frequency
; @ret		offset (sin)
; stdcall
; fn sinwave(t: f32, p: f32, a: f32, f: f32) f32
sinwave:
	push	ebp
	mov		ebp, esp
	; wave
	fld		dword [ebp+12]			; phase
	fmul	dword [ebp+20]			; frequency
	fadd	dword [ebp+8]			; t
	fld		dword [f32_tau]
	fxch
	fprem1
	fsin
	fmul	dword [ebp+16]			; amplitude
	fxch
	fstp	st0						; pop and discard from fpu stack
	fstp	dword [ebp+8]
	mov		eax, [ebp+8]
	; epilogue
	pop		ebp
	ret		16

; simpler sinwave generation with non-pessimized logic for use cases that don't 
;  need phase/frequency
; @a		amplitude
; @ret		offset (sin)
; stdcall
; fn sinwave_simple(t: f32, a: f32) f32
sinwave_simple:
	push	ebp
	mov		ebp, esp
	; wave
	fld		dword [ebp+8]			; t
	fld		dword [f32_tau]
	fxch
	fprem1
	fsin
	fmul	dword [ebp+12]			; amplitude
	fxch
	fstp	st0
	fstp	dword [ebp+8]
	mov		eax, [ebp+8]
	; epilogue
	pop		ebp
	ret		8

; convenience functions for dealing with the fact that fpu only uses memory refs

; stdcall
; fn f32toi(f32) i32
f32toi:
	fld		dword [esp+4]
	fistp	dword [esp+4]
	mov		eax, [esp+4]
	ret		4

; stdcall
; fn i32tof(i32) f32
i32tof:
	fild	dword [esp+4]
	fstp	dword [esp+4]
	mov		eax, [esp+4]
	ret		4

; stdcall
; fn f32mul(f32, f32) f32
f32mul:
	fld		dword [esp+4]
	fmul	dword [esp+8]
	fstp	dword [esp+4]
	mov		eax, [esp+4]
	ret		8

; stdcall
; fn f32div(f32, f32) f32
f32div:
	fld		dword [esp+4]
	fdiv	dword [esp+8]
	fstp	dword [esp+4]
	mov		eax, [esp+4]
	ret		8



%endif
