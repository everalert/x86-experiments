%ifndef _VBUF_SPRITE_S_
%define _VBUF_SPRITE_S_


%include "vbuf.s"


section .data
	
	spr_test_8bit			db 0x20,0x30,0x38,0x3C,0x38,0x30,0x20,0x00,	; 0x10
	;spr_test_8bit			db 0x08,0x0C,0x0E,0x0F,0x0E,0x0C,0x08,0x00,	; 0x10
	sprlen_test_8bit		equ $-spr_test_8bit


section .text

; draw 8px-wide 1-bit alpha sprite. each data byte is one row of 8 pixels, drawn
;  in MSB-first order (i.e. the order when written in 0bNNNNNNNN notation).
; fn vbuf_draw_sprite_1b8(color: u32, x: i16, y: i16, h: u8, data: [*]const u8) callconv(.stdcall) void
vbuf_draw_sprite_1b8:
	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	push	ecx
	push	edx
	; draw sprite
	xor		edx, edx
	xor		ecx, ecx
	xor		ebx, ebx
	mov		dx, word [ebp+14]		; y
	mov		ch, byte [ebp+16]		; h
	mov		eax, [ebp+20]			; data
.oloop:
	dec		ch
	jl		.oloop_end
	push	eax
	mov		al, byte [eax]
	mov		cl, 8
	mov		bx, word [ebp+12]		; x
	add		bx, 7					; last pixel is x+w(8)-1
.iloop:
	dec		cl
	jl		.iloop_end
	mov		ah, al
	and		ah, 1
	jle		.iloop_draw_ok
	push	edx
	push	ebx
	push	[ebp+8]
	call	vbuf_draw_pixel
.iloop_draw_ok:
	shr		al, 1
	dec		bx
	jmp		.iloop
.iloop_end:
	pop		eax
	inc		eax
	inc		dx
	jmp		.oloop
.oloop_end:
	; epilogue
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp
	ret		16


%endif
