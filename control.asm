ButtonCHandler:
	movem.l d0-d5, -(sp)

	move.w posX, d2
	move.w posY, d3
	jsr ReadPad1             ; Read pad 1 state, result in d0

	move.l #speed_moving_player, d4          ; Default sprite move speed speed

	btst #pad_button_a, d0   ; Check A button
	bne @NoA                 ; Branch if button off
	move.l #$02, d4          ; Double sprite move speed speed
	@NoA:

	btst #pad_button_b, d0
	bne @NoB
	move.l #$02, d4
	@NoB:

	btst #pad_button_c, d0
	bne @NoC_Unlock
	jsr JumpHandler
	move.w #$01, jump_lock_bool
	jmp @NoC
	@NoC_Unlock:
	move.w #$00, jump_lock_bool
	@NoC:

	btst #pad_button_start, d0
	bne @NoStart
	move.l #$02, d4
	@NoStart:

	btst #pad_button_right, d0
	bne @NoRight
	move.b var_block_posX_right, d5
	cmpi.b #boolean_true, d5
	beq @NoRightAndUnblock
	add.w d4, d2
	jmp @NoRight
	@NoRightAndUnblock:
	move.w d4, d1
	jsr BlockCameraRight
	nop
	;scc d4
	@NoRight:

	btst #pad_button_left, d0
	bne @NoLeft
	move.b var_block_posX_left, d5
	cmpi.b #boolean_true, d5
	beq @NoLeftAndUnblock
	sub.w d4, d2
	jmp @NoLeft
	@NoLeftAndUnblock:
	move.w d4, d1
	jsr BlockCameraLeft
	@NoLeft:

	btst #pad_button_down, d0
	bne @NoDown
	;add.w d4, d3
	@NoDown:

	btst #pad_button_up, d0
	bne @NoUP
	;sub.w d4, d3
	@NoUP:

	move.w d2, posX
	move.w d3, posY

	movem.l (sp)+, d0-d5
	rts
;==========================================================
SetSpritePosX:
	; Set sprite Xposition
	; d0 (b) - Sprite ID
	; d1 (w) - X coord
	clr.l d3                           ; Clear d3
	move.b d0, d3                      ; Move sprite ID to d3

	mulu.w #$08, d3                    ; Sprite array offset
	add.b  #$06, d3                    ; X coord offset
	swap d3                            ; Move to upper word
	add.l  #vdp_write_sprite_table, d3 ; Add to sprite attr table (at 0xD400)

	move.l d3, vdp_control             ; Set dest address
	move.w d1, vdp_data                ; Move X pos to data port

	rts
;==========================================================
SetSpritePosY:
	; Set sprite Y position
	; d0 (b) - Sprite ID
	; d1 (w) - Y coord
	clr.l	d3						; Clear d3
	move.b	d0, d3					; Move sprite ID to d3
	
	mulu.w	#0x8, d3				; Sprite array offset
	swap	d3						; Move to upper word
	add.l	#vdp_write_sprite_table, d3	; Add to sprite attr table (at 0xD400)
	
	move.l	d3, vdp_control			; Set dest address
	move.w	d1, vdp_data			; Move X pos to data port
	
	rts
;==========================================================