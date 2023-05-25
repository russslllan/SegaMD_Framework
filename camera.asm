; ********************************************
; Camera
; ********************************************
;==========================================================
update_scroll:
    move.l d0, -(sp)

	move.w var_hs_scroll, d0
	move.l #vdp_write_hscroll, vdp_control
	move.w d0, vdp_data

    move.l (sp)+, d0
	rts
;==========================================================
BlockCameraRight
    ; d1 value
    move.l d1, -(sp)

	move.b #boolean_false, var_block_posX_left
	sub.w d1, var_hs_scroll

    move.l (sp)+, d1
    rts
;==========================================================
BlockCameraLeft
    ; d1 value
    move.l d1, -(sp)

	move.b #boolean_false, var_block_posX_right
	add.w d1, var_hs_scroll

    move.l (sp)+, d1
    rts
;==========================================================
BlockScroll:
	move.l d0, -(sp)

	move.w posX, d0
	cmpi.w #scroll_border_left, d0
	ble @BlockScrollLeft
	jmp @NoBlockScrollLeft
	@BlockScrollLeft:
	move.b #boolean_true, var_block_posX_left
	@NoBlockScrollLeft:

	move.w posX, d0
	cmpi.w #scroll_border_right, d0
	bge @BlockScrollRight
	jmp @NoBlockScrollRight
	@BlockScrollRight:
	move.b #boolean_true, var_block_posX_right
	@NoBlockScrollRight:

	move.l (sp)+, d0
	rts
;==========================================================
;;ScrollHandler
	;movem.l d0-d7/a0-a7, -(sp)

	;move.b var_block_posX_left, d7
	;cmp #boolean_true, d7
	;bne @NoScroll
	;move.b var_block_posX_right, d7
	;cmp #boolean_true, d7
	;bne @NoScroll
	;move.w #$0000, d1
	;sub.w posX, d1
	;move.w d1, var_hs_scroll
	;move.w #$0000, d1; d1 value
	;@NoScroll:

	;movem.l (sp)+, d0-d7/a0-a7
	;rts
;==========================================================