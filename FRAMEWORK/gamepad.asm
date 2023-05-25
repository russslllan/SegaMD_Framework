; **************************************
; Controller
; **************************************

Controller_Init:

	move.b #0x00, 0x000A10009   ; Controller port 1 CTRL
	move.b #0x00, 0x000A1000B   ; Controller port 2 CTRL
	move.b #0x00, 0x000A1000D   ; EXP port CTRL

	rts

ReadPad1:
	; d0 (w) - Return result (00SA0000 00CBRLDU)
	move.b  pad_data_a, d0     ; Read upper byte from data port
	rol.w   #0x8, d0           ; Move to upper byte of d0
	move.b  #0x40, pad_data_a  ; Write bit 7 to data port
	move.b  pad_data_a, d0     ; Read lower byte from data port
	move.b  #0x00, pad_data_a  ; Put data port back to normal

	rts