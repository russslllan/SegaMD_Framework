; *****************************
; works with a stack
; *****************************

PUSHW: macro reg
    move.w \reg, -(sp)
    endm

POPW: macro reg
    move.w (sp)+, \reg
    endm

PUSHL: macro reg
    move.l \reg, -(sp)
    endm

POPL: macro reg
    move.l (sp)+, \reg
    endm

PUSHALL: macro 
    movem.l d0-d7/a0-a7, -(sp)
    endm

POPALL: macro
    movem.l (sp)+, d0-d7/a0-a7
    endm

; *************************************
; status register
; *************************************
status_reg_int2			equ (1<<10)
status_reg_int1			equ (1<<9)
status_reg_int0			equ (1<<8)

status_reg_disable     equ (status_reg_int0|status_reg_int1|status_reg_int2)

DISABLE_INTERRUPTS: macro
    PUSHW sr
    ori.w #status_reg_disable, sr
    endm

RESTORE_INTERRUPTS: macro
    POPW sr
    endm

; Set VDP register state (and update local table)
VDP_SETREG: macro regnum,valuereg
	move.b \valuereg,(vdp_regs+\regnum)
	andi.w #0x00FF,\valuereg
	ori.w  #((0x80|(\regnum))<<8),\valuereg
	move.w \valuereg, vdp_control
	endm
	
; Get VDP register state from local table
VDP_GETREG: macro regnum,valuereg
	move.b (vdp_regs+\regnum),\valuereg
	endm

Echo_Z80Release: macro
    move.w  #$000, ($A11100)        ; Release Z80 bus
    endm                            ; End of macro

Echo_Z80Request macro
    move.w  #$100, ($A11100)        ; Request Z80 bus
@Echo_WaitZ80\@:
    btst.b  #0, ($A11100)           ; Did we get it yet?
    bne.s   @Echo_WaitZ80\@         ; Keep waiting
    endm                            ; End of macro

; 'even' equivalent for RS
RS_ALIGN: macro
	if __RS&1
	rs.b 1
	endc
	endm

    
Echo_Z80Reset macro
    move.w  #$000, ($A11200)        ; Assert reset line
    rept    $10                     ; Wait until hardware resets
    nop                               ; ...
    endr                              ; ...
    move.w  #$100, ($A11200)        ; Release reset line
    endm                            ; End of macro

Echo_ListEntry macro addr
    dc.b    $80|((addr)>>8&$7F)                 ; High byte of address
    dc.b    (addr)&$FF                          ; Low byte of address
    dc.b    ((addr)>>15&$7F)|((addr)>>16&$80)   ; Bank number
    endm

Echo_ListEnd macro
    dc.b    $00                     ; End of list mark
    even                            ; Just in case...
    endm

SetVRAMWrite: macro addr
	move.l  #(vdp_cmd_vram_write)|((addr)&$3FFF)<<16|(addr)>>14, vdp_control
	endm

