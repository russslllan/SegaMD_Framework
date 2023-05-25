; ********************************************
; Player
; ********************************************
MovePlayer:
	;movem.l d0-d7/a0-a7, -(sp)

	jsr BlockScroll
	jsr ButtonCHandler
	jsr DoGravity
	jsr JumpPlayer
	
	;movem.l (sp)+, d0-d7/a0-a7
	rts
;==========================================================
JumpPlayer:

	movem.l d0-d1, -(sp)

	cmp.w #$01, jump_bool
	bne @EndJumpPlayer
	cmp.w #$00, jump_count
	beq @EndJumpCountPlayer
	move.w posY, d1
	move.w speed, d0
	add.w #$03, d0
	sub.w  d0, d1
	move.w d1, posY
	sub.w  #$01, jump_count
	jmp @EndJumpPlayer
	@EndJumpCountPlayer:
	move.w #$00, jump_bool
	@EndJumpPlayer:

	movem.l (sp)+, d0-d1
	rts
;==========================================================
JumpHandler:
	;movem.l d0-d7/a0-a7, -(sp)

	cmp.w #$01, jump_floor_bool
	bne @EndBtnCHandler
	cmp.w #$00, jump_bool
	bne @EndBtnCHandler
	move.w #$01, jump_bool
	move.w #count_for_jump, jump_count	
	@EndBtnCHandler:

	;movem.l (sp)+, d0-d7/a0-a7
	rts
;==========================================================
UpdateMovePlayer:
	movem.l d0-d1, -(sp)

	move.w #$0000, d0         ; Sprite ID
	clr.l d1
	move.w posX, d1             ; X coord
	jsr SetSpritePosX         ; Set X pos


	move.w posY, d1
	jsr SetSpritePosY         ; Set Y pos

	movem.l (sp)+, d0-d1
	rts
;==========================================================