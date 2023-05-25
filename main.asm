	org 0
	include 'constants.inc'
	include 'init.asm'
	;nop 0,2

;PixelFontVRAM  		equ 0x0000
;Sprite1VRAM    		equ PixelFontVRAM+PixelFontSizeB
;Sprite2VRAM    		equ Sprite1VRAM+Sprite1SizeB
;FloorLevelVRAM      equ Sprite2VRAM+Sprite2SizeB
spriteSonic3VRAM    equ $0000
Sprite1VRAM    		equ $1000;spriteSonic3VRAM+spriteSonic3SizeB
Sprite2VRAM    		equ $1500;Sprite1VRAM+Sprite1SizeB

__main:

	bra StartGame

;ResetX:
	;move.l #$00000080, d1
	;jmp Loop

DrawtextPlaneA:
	; a0 (l) - String address
	; d0 First tile ID of font
	; d1 (bb) - XY coord (in tiles)
	; d2 (b) - Palette

	clr.l d3                      ; Clear d3 ready to work with
	move.b d1, d3                 ; Move Y coord (lower byte of d1) to d3
	mulu.w #$0040, d3             ; Multiply Y by line width (H40 mode - 64 lines horizontally) to get Y offset
	ror.l #$08, d1                ; Shift X coord from upper to lower byte of d1
	add.b d1, d3                  ; Add X coord to offset
	mulu.w #$02, d3               ; Convert to words
	swap d3                       ; Shift address offset to upper word
	add.l #vdp_write_plane_a, d3  ; Add PlaneA write cmd + address
	move.l d3, vdp_control         ; Send to VDP control port

	clr.l d3                      ; Clear d3 ready to work with again
	move.b d2, d3                 ; Move palette ID (lower byte of d2) to d3
	rol.l #$08, d3                ; Shift palette ID to bits 14 and 15 of d3
	rol.l #$05, d3                ; Can only rol bits up to 8 places in one instruction

	lea ASCIIMap, a1              ; Can only rol bits up to 8 places in one instruction
	@CharCopyTextA:                   
	move.b (a0)+, d2              ; Move ASCII byte to lower byte of d2
	cmp.b #$00, d2                ; Test if byte is zero (string terminator)
	beq.b @EndTextA                   ; If byte was zero, branch to end

	sub.b  #ASCIIStart, d2        ; Subtract first ASCII code to get table entry index
	move.b (a1, d2.w), d3         ; Move tile ID from table (index in lower word of d2) to lower byte of d3
	add.w d0, d3                  ; Offset tile ID by first tile ID in font
	move.w d3, vdp_data            ; Move palette and pattern IDs to VDP data port
	jmp @CharCopyTextA               ; Next character

	@EndTextA:
	rts
;==========================================================
Delay:
	; d0 - delay time 
	@PDelay:
	dbra d0, @PDelay
	rts

;==========================================================
CopyMemory:
	; a0 1st source      address
	; a1 2st destination address
	; d0 length in bytes

	sub.l #$01, d0
	@CopyMemory:
	move.b (a0)+, (a1)+ 
	dbra d0, @CopyMemory

	rts
;==========================================================

	include 'defs.inc'
	include 'macros.asm'
	include 'Variables.asm'
	include 'sprite2.asm'
	include 'paletteset1.asm'
	include 'ascii.asm'	
	include '.\FRAMEWORK\vdputils.asm'
	include 'game.asm'
	include 'camera.asm'
	include 'control.asm'
	include 'physics.asm'
	
	
	include 'timing.asm'
	include '.\FRAMEWORK\gamepad.asm'
	include 'sprite1.asm'
	include 'pixelfont_1.asm'
	include 'spriteSonic3.asm'
	include 'palSonic3.asm'
	include 'nameTable.asm'
	include 'floor.asm'
	include '.\FRAMEWORK\interrupts.asm'
	include '.\FRAMEWORK\Z80.asm'
	include '.\FRAMEWORK\VDP.asm'
	include 'Player.asm'
	;include 'SOUND.ASM'
	;include 'ASSETS\AUDIO\INSTRS.ASM'
;msc_title: include 'ASSETS\AUDIO\TRACKS\TITLES.ASM'
;msc_boss:  include 'ASSETS\AUDIO\TRACKS\BOSS_Q.ASM'

String1:
	dc.b "HELLO SEGA !!!",0
__end:


