%ifndef	_VBUF_S_
%define	_VBUF_S_


%include "win32.s"


struc ScreenBuffer
	.Width							resd 1
	.Height							resd 1
	.BytesPerPixel					resd 1
	.Pitch							resd 1
	.Memory							resd 1
	.hBitmap						resd 1
	.Info							resb BITMAPINFOHEADER_size
endstruc

struc ScreenSize
	.W								resw 1
	.H								resw 1
endstruc


section .data
	
	vbuf_bindumptestdata			db "bindumptestdata0123456789",0


section .bss

	BackBuffer						resb ScreenBuffer_size
	FrameCount						resd 1


section .text

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
	and		ecx, dword 0x00003F				; 0xRRGGBB
	shr		ecx, 2
	add		ecx, dword 0xF
	push	ecx
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
	; b8
	push	0xAA
	push	32
	push	16
	push	0xFFFF00
	call	vbuf_draw_b8
	; bindump
	push	4
	push	8
	push	vbuf_bindumptestdata
	push	64
	push	16
	push	0xFFFF00
	call	vbuf_draw_bindump
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

DrawBinDump_GapX	equ 8
DrawBinDump_GapY	equ 4
DrawBinDump_StepW	equ DrawB8_StepWAll+DrawBinDump_GapX
DrawBinDump_StepH 	equ DrawB8_H+DrawBinDump_GapY
; stdcall
; fn vbuf_draw_bindump(col: u32, x: i32, y:i32, data: [*]const u8, len: u32, row_sz: u32) void
vbuf_draw_bindump:
	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	push	ecx
	push	edx
	sub		esp, 12
	; work
	mov		edx, esp
	mov		eax, [ebp+12]			; x
	mov		[edx+0], eax
	mov		eax, [ebp+16]			; y
	mov		[edx+4], eax
	mov		eax, dword DrawBinDump_StepW
	mul		eax, [ebp+28]			; step_w_all
	mov		[edx+8], eax
	mov		ebx, [ebp+20]			; data
.data:
	cmp		dword [ebp+24], 0
	jle		.data_done
	mov		ecx, dword [ebp+28]		; row_sz
.data_inner:
	dec		ecx
	jl		.data_inner_done
	push	[ebx]					; val
	push	[edx+4]					; y
	push	[edx+0]					; x
	push	[ebp+8]					; col
	call	vbuf_draw_b8
	add		dword [edx+0], DrawBinDump_StepW
	inc		ebx
	dec		dword [ebp+24]
	jg		.data_inner
.data_inner_done:
	mov		eax, [edx+8]
	sub		dword [edx+0], eax
	add		dword [edx+4], DrawBinDump_StepH
	jmp		.data
.data_done:
	; epilogue
	add		esp, 12
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp
	ret		24

DrawB8_Gap			equ 4
DrawB8_W			equ 8
DrawB8_H			equ 16
DrawB8_StepW		equ DrawB8_W+DrawB8_Gap
DrawB8_StepWAll 	equ DrawB8_StepW*8
; stdcall
; fn vbuf_draw_b8(col: u32, x: i32, y:i32, val: u8) void
vbuf_draw_b8:
	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	push	ecx
	push	edx
	; work
	mov		ebx, [ebp+20]			; val
	mov		eax, [ebp+12]			; x
	add		eax, DrawB8_StepWAll
	mov		ecx, 8					; ecx = i
.loop:
	sub		eax, DrawB8_StepW		; x += 6
	dec		ecx
	jl		.loop_end
	push	DrawB8_H				; h
	push	DrawB8_W				; w
	push	dword [ebp+16]			; y
	push	eax						; x
	push	dword [ebp+8]			; col
	mov		edx, ebx
	and		edx, 0x1
	jnz		.draw_fill
	call	vbuf_draw_rect
	jmp		.draw_ok
.draw_fill:
	call	vbuf_draw_rect_fill
.draw_ok:
	shr		ebx, 1					; val >> 1
	jmp		.loop
.loop_end:
	; epilogue
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp
	ret		16


%endif
