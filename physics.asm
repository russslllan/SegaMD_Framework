DoGravity:
	movem.l d0-d7/a0-a7, -(sp)

	move.w posY, d1             ; Y coord
	move.w floor, d7
	cmp.w d1, d7
	bgt @DoGrav
	jmp @NoGrav
	@DoGrav:
	move.w gravity, d7
	add.w d7, d1
	move.w d1, posY
	@noGrav:
	cmp.w floor, d1
	bgt @DoFloor
	jmp @NoFloor
	@DoFloor:
	move.w floor, d1
	move.w d1, posY
	@NoFloor:
	cmp.w floor, d1
	beq @EqualFloor
	jmp @NotEqualFloor
	@EqualFloor:
	cmp.w #$01, jump_lock_bool
	beq @EndEqualFloor
	move.w #$01, jump_floor_bool
	jmp @EndEqualFloor
	@NotEqualFloor:
	move.w #$00, jump_floor_bool
	@EndEqualFloor:

	movem.l (sp)+, d0-d7/a0-a7
	rts
;==========================================================