WaitVSync:
    move.w vdp_control, d0    ; Move VDP status word to d0
    andi.w #$08, d0           ; AND with bit 4 (vblank), result in status register
    beq WaitVSync             ; Branch if equal (to zero)
    rts