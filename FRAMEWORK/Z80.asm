; **********************************
; Z80 sound cpu
; **********************************

Z80_Init:

	move.w #0x0100, z80_bus_request ; Request access to the Z80 bus, by writing 0x0100 into the BUSREQ port
	move.w #0x0100, z80_bus_reset   ; Hold the Z80 in a reset state, by writing 0x0100 into the RESET port

	@Wait:
	btst #0x0, z80_bus_request ; Test bit 0 of A11100 to see if the 68k has access to the Z80 bus yet
	bne @Wait                  ; If we don't yet have control, branch back up to Wait
	
	move.l #z80_ram_start, a1    ; Z80 RAM start
	move.l #z80_ram_size_b-1, d0 ; 8KB (-1 for loop counter)
	@CopyZ80:
	move.b #0x0, (a1)+           ; Clear byte, increment dest address
	dbra d0, @CopyZ80

	move.w #0x0000, z80_bus_reset    ; Release reset state
	move.w #0x0000, z80_bus_request  ; Release control of bus
	
	rts

Z80_Init1:
        ; a0 address Z80 data
        ; d0 size data

	move.w #$0100, $00A11100    ; Request access to the Z80 bus, by writing 0x0100 into the BUSREQ port
	move.w #$0100, $00A11200    ; Hold the Z80 in a reset state, by writing 0x0100 into the RESET port

	@Wait:
	btst #$00, $00A11100        ; Test bit 0 of A11100 to see if the 68k has access to the Z80 bus yet
	bne @Wait                   ; If we don't yet have control, branch back up to Wait

	move.l #Z80Data, a0         ; Load address of data into a0
	move.l #$00A00000, a1       ; Copy Z80 RAM address to a1
	move.l #$29, d0             ; 42 bytes of init data (minus 1 for counter)

        subq #$01, d0
	@CopyZ80:
	move.b (a0)+, (a1)+         ; Copy data, and increment the source/dest addresses
	dbra d0, @CopyZ80

        rts
Z80_TakeBus:

        move.w #$0100, z80_bus_request

        @WaitZ80Bus:
        btst #$00, z80_bus_request
        bne @WaitZ80Bus

        rts

Z80_ReleaseBus:
    move.w #$0000, z80_bus_request
    rts