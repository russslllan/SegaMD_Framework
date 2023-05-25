StartGame:
	move.w #$8F02, vdp_control      ; Set autoincrement to 2 


	; ************************************
	; Move palettes to CRAM
	; ************************************
	move.l #vdp_write_palettes, vdp_control
	lea    palSonic3, a0
	move.l #$1E, d0
	@PaletteLoop:
	move.l (a0)+, vdp_data
	dbra d0, @PaletteLoop
	
	move.l #vdp_write_palettes, vdp_control       ; Set up VDP to write to CRAM address 0x0000

	lea PaletteSprites, a0                        ; Load address of Palettes into a0
	move.l #$0F, d0                               ; 64 bytes of data (2 palettes, 16 longwords, minus 1 for counter) in palettes

	@ColorLoop:
	move.l (a0)+, vdp_data                        ; Move data to VDP data port, and increment source address
	dbra d0, @ColorLoop

	; ************************************
	; Load floor level
	; ************************************
	;lea FloorLevel, a0
	;move.l #FloorLevelVRAM, d0
	;move.l #FloorLevelSizeT, d1
	;jsr VDP_LoadTiles


	; ************************************
	; Load font
	; ************************************
	;lea pixelfont, a0                            ; Move font address to a0
	;move.l #PixelFontVRAM, d0                    ; Move VRAM dest address to d0
	;move.l #PixelFontSizeT, d1                   ; Move number of characters (font size in tiles) to d1
	;jsr VDP_LoadTiles                                ; Jump to subroutine

	;jsr VDP_WriteToPlaneA

	;lea spriteSonic3, a0
	;lea free_memory, a1
	;move.l #spriteSonic3SizeB, d0
	;jsr CopyMemory

	lea spriteSonic3, a0
	move.l #spriteSonic3VRAM, d0
	move.l #spriteSonic3SizeT, d1
	jsr VDP_LoadTiles

	lea nameTable, a0
	move.l #nameTableSizeL, d0
	jsr VDP_WriteToPlaneA1

	; ************************************
	; Load sprite tiles
	; ************************************
	lea Sprite1, a0                               ; Move sprite address to a0
	move.l #Sprite1VRAM, d0                       ; Move VRAM dest address to d0
	move.l #Sprite1SizeT, d1                      ; Move number of tiles to d1
	jsr VDP_LoadTiles                                 ; Jump to subroutine

	lea Sprite2, a0
	move.l #Sprite2VRAM, d0
	move.l #Sprite2SizeT, d1
	jsr VDP_LoadTiles

	;lea FloorLevel,  a0
	;lea free_memory, a1
	;move.l #FloorLevelSizeB, d0
	;jsr CopyMemory

	;lea free_memory, a0
	;move.l #$FFE0, d0
	;move.l #FloorLevelSizeW, d1
	;jsr VDP_LoadTilesDMA

	; ************************************
	; Load sprite descriptors
	; ************************************
	lea SpriteDescs, a0                           ; Sprite table data
	move.w #$02, d0                               ; 2 sprites
	jsr VDP_LoadSpriteTables


	; Draw text
	;lea String1, a0                  ; String address
	;.l #PixelFontTileID, d0      ; First tile id
	;move.w #$0502, d1                ; XY (05, 2)
	;move.l #$00000000, d2            ; Palette 0
	;jsr DrawtextPlaneA               ; Call draw text subroutine

		; ************************************
	; Set sprite positions
	; ************************************

	move.w #$01, d0                               ; Sprite ID
	move.w #$A0, d1                               ; X coord
	jsr    SetSpritePosX                          ; Set X pos
	move.w #$90, d1                               ; Y coord
	jsr    SetSpritePosY                          ; Set Y pos

	move.w  #$0001, speed
	move.w  #$0002, gravity
	move.w  #$0140, floor
	move.w  #start_posX_player, posX
	move.w  #start_posY_player, posY
	move.w  #$00, jump_bool

	move.w #$0000, var_hs_scroll

	;move.b #boolean_false, var_block_posX
	;PUSH  a0/d0-d1
	;lea msc_boss, a0
	;jsr SND_PlayTrack
	;POP   a0/d0-d1

	;jmp Loop
	; main loop
MainLoop:
	;move.w #$00, d0                               ; Sprite ID
	;cmp    #$1C0, d1
	;beq    ResetX
	;add.w  #$01, d1 
	;jsr    SetSpritePosX                         ; Set X pos
	;move.l #$FFFF, d0
	;jsr Delay

	jsr MovePlayer
	;jsr ScrollHandler

	; ************************************
	; Update sprites during vblank
	; ************************************
	;====================================================
	jsr WaitVBlankStart       ; Wait for start of vblank

	jsr UpdateMovePlayer
	jsr update_scroll

	jsr WaitVBlankEnd         ; Wait for end of vblank
	;====================================================
	; ************************************
	; End update sprites during vblank
	; ************************************

	jmp MainLoop

;==========================================================
SpriteDescs:
    dc.w 0x0000        ; Y coord (+ 128)
    dc.b %00001111     ; Width (bits 0-1) and height (bits 2-3) in tiles
    dc.b 0x01          ; Index of next sprite (linked list)
    dc.b 0x00          ; H/V flipping (bits 3/4), palette index (bits 5-6), priority (bit 7)
    dc.b Sprite1TileID ; Index of first tile
    dc.w 0x0000        ; X coord (+ 128)

	dc.w 0x0000        ; Y coord (+ 128)
    dc.b %00001111     ; Width (bits 0-1) and height (bits 2-3) in tiles
    dc.b 0x00          ; Index of next sprite (linked list)
    dc.b 0x20          ; H/V flipping (bits 3/4), palette index (bits 5-6), priority (bit 7)
    dc.b Sprite2TileID ; Index of first tile
    dc.w 0x0000        ; X coord (+ 128)
;==========================================================