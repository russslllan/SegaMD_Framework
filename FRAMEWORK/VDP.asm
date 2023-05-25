; ********************************************
; VDP
;*********************************************

VDP_Init:
	; a0 address registers
	; d0 data size
 	
	;move.l #VDPRegisters, a0    ; Load address of register table into a0
	;move.l #$18, d0             ; 24 registers to write
	move.l #$00008000, d1       ; 'Set register 0' command (and clear the rest of d1 ready)

	DISABLE_INTERRUPTS

	@CopyVDP:
	move.b (a0)+, d1            ; Move register value to lower byte of d1
	move.w d1, 0x00C00004        ; Write command and value to VDP control port
	add.w #$0100, d1            ; Increment register #
	dbra d0, @CopyVDP

	move.l #forReg1, d4
	VDP_SETREG 1, d4

	RESTORE_INTERRUPTS

	jsr VDP_ClearVRAM

	rts

VDP_ClearVRAM:

	DISABLE_INTERRUPTS

	move.w #0x8F02, vdp_control     ; Set autoincrement to 1 byte
	move.w #0x93FF, vdp_control     ; Set bytes to fill (lo) (reg 19)
	move.w #0x94FF, vdp_control     ; Set bytes to fill (hi) (reg 20)
	move.w #0x9780, vdp_control     ; Set DMA to Fill (reg 23, bits 0-1)
	move.l #vdp_cmd_dma_vram_write, vdp_control ; Set destination address
	move.w #0x0, vdp_data           ; Value to write

	RESTORE_INTERRUPTS

	@WaitForDMA_vram:                    
	move.w vdp_control, d1          ; Read VDP status reg
	btst   #0x1, d1                 ; Check if DMA finished
	bne.s  @WaitForDMA_vram
	
	rts

VDP_LoadFont:
	; a0 - Font address (l)
	; d0 - VRAM address
	; d1 - Num chars

	swap d0                      ; Shift VRAM addr to upper word
	add.l #vdp_write_tiles, d0   ; VRAM write cmd + VRAM destination address
	move.l d0, vdp_control       ; Send address to VDP cmd port

	subq.b #$01, d1              ; Num chars - 1
	@CharCopyFont:    
	move.w #$07, d2              ; 8 longwords in tile
	@LongCopyFont:
	move.l (a0)+, vdp_data       ; Copy one line of tile to VDP data port
	dbra d2, @LongCopyFont
	dbra d1, @CharCopyFont

	rts
;==========================================================
VDP_LoadTiles:
	; a0 - Font address (l)
	; d0 - VRAM address (w)
	; d1 - Num chars (b)
	
	swap	d0						; VRAM addr in upper word
	add.l	#vdp_write_tiles, d0	; VRAM write cmd + VRAM destination address
	move.l	d0, vdp_control			; Send address to VDP cmd port
	
	subq.b	#0x1, d1				; Num chars - 1
	@CharCopy:
	move.w	#0x07, d2				; 8 longwords in tile
	@LongCopy:
	move.l	(a0)+, vdp_data			; Copy one line of tile to VDP data port
	dbra	d2, @LongCopy
	dbra	d1, @CharCopy
	
	rts
;==========================================================
VDP_LoadTilesDMA:
	; a0 - Font address (l)
	; d0 - VRAM address (w)
	; d1 - Num words (w)

	@BusyDMA:
	move.w vdp_control, d3
	btst  #$02, d3
	bne @BusyDMA

	DISABLE_INTERRUPTS

	;move.l #vdp_register_1, d2
	;move.b  #$74, d2
	;move.w d2, vdp_control

	; size lo
	move.w d1, d2
	andi.w #0x00FF, d2
	ori.w  #vdp_register_19, d2
	move.w d2, vdp_control

	; size hi
	lsr.w  #0x8, d1
	andi.w #0x00FF, d1
	ori.w  #vdp_register_20, d1
	move.w d1, vdp_control

	; source address lo 
	move.l #vdp_register_21, d2
	move.l a0, d3
	lsr.l #$01, d3
	move.b  d3, d2
	move.w d2, vdp_control

	; source address mid
	move.l #vdp_register_22, d2
	lsr.l  #$08, d3
	move.b d3, d2
	move.w d2, vdp_control

	; source address hi 
	move.l #vdp_register_23, d2
	lsr.l  #$08, d3
	andi.b #$7F, d3
	move.b d3, d2
	move.w d2, vdp_control

	swap d0
	move.l d0, d2
	and.l #$C0000000, d2
	and.l #$3FFFFFFF, d0
	move.l #$1E, d3
	lsr.l d3, d2
	ori.l #vdp_write_tiles, d0
	or.l d2, d0
	ori.l #$80, d0

	;move.l #vdp_num_registers, d5

	; Read VDP reg 1
	VDP_GETREG 1, d4

	; Enable DMA
	ori.w   #0x10, d4  			; Set register 1 + DMA bit (5)
	VDP_SETREG 1, d4

	move.l  d0, -(sp)
	move.w  (sp)+, vdp_control      ; Move dest address to VDP control port

	jsr Z80_TakeBus
	;move.l d0, vdp_control
	jsr Z80_ReleaseBus

	move.w  (sp)+, vdp_control      ; Move dest address to VDP control port

	; Disable DMA
	andi.b  #0xEF, d4 				; Clear DMA bit (5)
	VDP_SETREG 1, d4

	;@BusyDMA:
	;move.w vdp_control, d3
	;btst  #$02, d3
	;bne @BusyDMA

	;move.l #vdp_register_1, d2
	;move.b #$64, d2
	;move.w d2, vdp_control

	RESTORE_INTERRUPTS

	rts

;===================================================

VDP_VRAMCopy:
	; d0 (w) Source address (VRAM)
	; d1 (w) Dest address (VRAM)
	; d2 (w) Size (in bytes)

	DISABLE_INTERRUPTS
	
	; Size lo (register 13)
	move.w d2, d5
	andi.w #0x00FF, d5
	ori.w  #0x9300, d5
	move.w d5, vdp_control
	
	; Size hi (register 14)
	lsr.w  #0x8, d2
	andi.w #0x00FF, d2
	ori.w  #0x9400, d2
	move.w d2, vdp_control

	; Copy source address
	move.l a0, d5
	moveq #0x0, d3
	
	; Address byte 0 (register 15)
	move.w #0x9500, d3
	move.b d5, d3
	move.w d3, vdp_control
	
	; Address byte 1 (register 16)
	lsr.l  #0x8, d5					; Next byte
	move.w #0x9600, d3
	move.b d5, d3
	move.w d3, vdp_control
	
	; DMA mode (register 17)
	move.w #0x9700, d3
	move.b #vdp_dma_mode_copy, d3	; DMA mode 0
	move.w d3, vdp_control
	
	; Generate dest command+address
	andi.w  #0xFFFF, d1
	lsl.l   #0x2, d1				; Shift bits 14/15 of dest address to bits 16/17
	lsr.w   #0x2, d1				; Shift lower word back
	swap    d1                     	; Swap address hi/lo
	ori.l   #vdp_cmd_dma_vram_write, d1 ; OR in VRAM+DMA write command
	
	; Read VDP reg 1 (DMA) and 15 (autoincrement)
	VDP_GETREG 0x1, d4
	VDP_GETREG 0xF, d5

	; Set autoincrement to 1
	move.w  #0x1, d3
	VDP_SETREG 0xF, d3
	
	; Enable DMA
	ori.w   #0x10, d4  				; Set register 1 + DMA bit (5)
	VDP_SETREG 0x1, d4
	
	; Initiate DMA - command must come from RAM, so push to stack and pop for write
	move.l  d1, -(sp)
	move.w  (sp)+, vdp_control      ; Move dest address to VDP control port
	move.w  (sp)+, vdp_control      ; Move dest address to VDP control port

	; Wait until done
	@Wait:
	move.w  (vdp_control), d0
	btst    #vdp_status_dma, d0
	bne     @Wait
	
	; Disable DMA, restore regs
	andi.b  #0xEF, d4 				; Clear DMA bit (5)
	VDP_SETREG 0x1, d4
	VDP_SETREG 0xF, d5

	RESTORE_INTERRUPTS
	
	rts

;==========================================================
VDP_VRAMCopyDMA:
	; a0 --- Source address (RAM/ROM)
	; d0 (w) Dest address (VRAM)
	; d1 (w) Size (in words)

	; Disable interrupts
	DISABLE_INTERRUPTS
	
	; Size lo (register 13)
	move.w d1, d2
	andi.w #0x00FF, d2
	ori.w  #0x9300, d2
	move.w d2, vdp_control
	
	; Size hi (register 14)
	lsr.w  #0x8, d1
	andi.w #0x00FF, d1
	ori.w  #0x9400, d1
	move.w d1, vdp_control

	; Copy source address
	move.l a0, d2
	moveq #0x0, d3
	
	; Address byte 0 (register 15)
	lsr.l  #0x1, d2					; Ignore first bit (address is always even)
	move.w #0x9500, d3
	move.b d2, d3
	move.w d3, vdp_control
	
	; Address byte 1 (register 16)
	lsr.l  #0x8, d2					; Next byte
	move.w #0x9600, d3
	move.b d2, d3
	move.w d3, vdp_control
	
	; Address byte 2 + DMA mode (register 17)
	lsr.l  #0x8, d2					; Next byte
	move.w #0x9700, d3
	move.b d2, d3
	andi.b #vdp_dma_addr_mask_write, d3	; Top byte mask (to fit DMA mode)
	ori.b  #vdp_dma_mode_write, d3	; DMA mode 0
	move.w d3, vdp_control
	
	; Generate dest command+address
	andi.l  #0xFFFF, d0
	lsl.l   #0x2, d0				; Shift bits 14/15 of dest address to bits 16/17
	lsr.w   #0x2, d0				; Shift lower word back
	swap    d0                     	; Swap address hi/lo
	ori.l   #vdp_cmd_dma_vram_write, d0 ; OR in VRAM+DMA write command
	
	; Read VDP reg 1
	VDP_GETREG 1, d4
	
	; Enable DMA
	ori.w   #0x10, d4  			; Set register 1 + DMA bit (5)
	VDP_SETREG 1, d4

	; Take Z80 bus
	jsr    Z80_TakeBus
	
	; Initiate DMA - command must come from RAM, so push to stack and pop for write
	move.l  d0, -(sp)
	move.w  (sp)+, vdp_control      ; Move dest address to VDP control port
	move.w  (sp)+, vdp_control      ; Move dest address to VDP control port

	; Release Z80 bus
	jsr    Z80_ReleaseBus
	
	; Disable DMA
	andi.b  #0xEF, d4 				; Clear DMA bit (5)
	VDP_SETREG 1, d4

	; Restore interrupts
	RESTORE_INTERRUPTS
	
	rts
;==========================================================
VDP_LoadTilesFullAddr:
	; a0 - Font address (l)
	; d0 - VRAM address (w)
	; d1 - Num chars (b)

	swap d0
	move.l d0, d2
	and.l #$C0000000, d2
	and.l #$3FFFFFFF, d0
	move.l #$1E, d3
	ror.l d3, d2
	add.l #vdp_write_tiles, d0
	add.l d2, d0
	move.l d0, vdp_control

	subq.b #$01, d1
	@CharCopyFullAddr:
	move.w #$07, d2
	@LongCopyFullAddr:
	move.l (a0)+, vdp_data
	dbra d2, @LongCopyFullAddr
	dbra d1, @CharCopyFullAddr

	rts
;==========================================================
VDP_LoadSpriteTables:
	; a0 - Sprite data address
	; d0 - Number of sprites
	move.l #vdp_write_sprite_table, vdp_control

	subq.b #$01, d0               ; 2 sprites attributes
	@AttrCopy:
	move.l (a0)+, vdp_data
	move.l (a0)+, vdp_data
	dbra d0, @AttrCopy

	rts
;==========================================================
VDP_WriteToPlaneA
	; d0 Tile ID
	; d1 (bb) - XY coord (in tiles)
	; d2 (b) - Palette
	
	move.l #%0000011111111111, d4
	move.l #$40A, d3
	swap d3
	add.l #vdp_write_plane_a, d3
	move.l d3, vdp_control
	move.w d4, vdp_data

	rts

;==========================================================

VDP_WriteToPlaneA1:
	; a0 from address
	; d0 long count

	move.l #vdp_write_plane_a, d1
	;swap d0
	;move.l d0, d2
	;and.l #$C0000000, d2
	;and.l #$3FFFFFFF, d0
	;move.l #$1E, d3
	;ror.l d3, d2
	;add.l #vdp_write_tiles, d0
	;add.l d2, d0
	move.l d1, vdp_control

	@WPlaneALoop:
	move.l (a0)+, vdp_data
	dbra d0, @WPlaneALoop
	rts

	