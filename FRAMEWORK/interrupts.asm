HBlankInterrupt:
   rte   ; Return

VBlankInterrupt:
	nop
	nop
	nop
	nop
	nop
	nop
	nop
   addi.l #0x01, vblank_counter    ; Increment vinterrupt counter
   rte

Exception:
   stop #$2700 ; Halt CPU
    rte