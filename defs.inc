; ************************************
; VDP
; ************************************

vdp_control				equ 0x00C00004
vdp_data				equ 0x00C00000

vdp_write_palettes		equ 0xF0000000
vdp_write_tiles			equ 0x40000000
vdp_write_plane_a		equ 0x40000003
vdp_write_sprite_table	equ 0x78000002;0x60000003

vdp_register_0          equ $8000
vdp_register_1          equ $8100
vdp_register_2          equ $8200
vdp_register_3          equ $8300
vdp_register_4          equ $8400
vdp_register_5          equ $8500
vdp_register_6          equ $8600
vdp_register_7          equ $8700
vdp_register_8          equ $8800
vdp_register_9          equ $8900
vdp_register_10         equ $8A00
vdp_register_11         equ $8B00
vdp_register_12         equ $8C00
vdp_register_13         equ $8D00
vdp_register_14         equ $8E00
vdp_register_15         equ $8F00
vdp_register_16         equ $9000
vdp_register_17         equ $9100
vdp_register_18         equ $9200
vdp_register_19         equ $9300
vdp_register_20         equ $9400
vdp_register_21         equ $9500
vdp_register_22         equ $9600
vdp_register_23         equ $9700
vdp_register_24         equ $9800

vdp_num_registers       equ $18

; VDP memory access commands (DMA)
vdp_cmd_dma_vram_write  equ 0x40000080
vdp_cmd_dma_cram_write  equ 0xC0000080
vdp_cmd_dma_vsram_write equ x400000090

; VDP scroll
vdp_write_hscroll       equ 0x50000003

; VDP DMA modes
vdp_dma_mode_write		equ 0x00
vdp_dma_mode_copy		equ 0xC0
vdp_dma_mode_fill		equ 0x80

; VDP status register bits
vdp_status_fifoempty       equ 0x9    ; FIFO Empty
vdp_status_fifofull        equ 0x8    ; FIFO Full
vdp_status_vintpending     equ 0x7    ; Vertical interrupt pending
vdp_status_spriteoverflow  equ 0x6    ; Sprite overflow on current scan line
vdp_status_spritecollision equ 0x5    ; Sprite collision
vdp_status_oddframe        equ 0x4    ; Odd frame
vdp_status_vblank          equ 0x3    ; Vertical blanking
vdp_status_hblank          equ 0x2    ; Horizontal blanking
vdp_status_dma             equ 0x1    ; DMA in progress
vdp_status_pal             equ 0x0    ; PAL mode flag


vdp_dma_addr_mask_write equ 0x7F

; ************************************
; Z80
; ************************************

z80_bus_request			equ 0x00A11100
z80_bus_reset			equ 0x00A11200
z80_ram_start			equ 0x00A00000
z80_ram_size_b			equ 0x2000

; ************************************
; Gamepad ports
; ************************************
pad_data_a				equ 0x00A10003
pad_data_b				equ 0x00A10005
pad_data_c				equ 0x00A10007
pad_ctrl_a				equ 0x00A10009
pad_ctrl_b				equ 0x00A1000B
pad_ctrl_c				equ 0x00A1000D

pad_button_up           equ 0x0
pad_button_down         equ 0x1
pad_button_left         equ 0x2
pad_button_right        equ 0x3
pad_button_a            equ 0xC
pad_button_b            equ 0x4
pad_button_c            equ 0x5
pad_button_start        equ 0xD

count_for_jump          equ $20

; ************************************
; other
; ************************************

forReg1                equ $74

; ************************************
; sound
; ************************************
INCLUDE_AUDIO			equ 1
Track_Type_COUNT		equ 0x4


; ************************************
; Sizes
; ************************************
size_byte:			equ 0x01
size_word:			equ 0x02
size_long:			equ 0x04
size_address		equ 0x04
size_spritedesc:	equ 0x08

ECHO_ENCRYPT_Z80		equ 0

; Levels
INCLUDE_LEVEL_1			equ 1
INCLUDE_LEVEL_2			equ 1
INCLUDE_LEVEL_3			equ 1
INCLUDE_LEVEL_4			equ 1
INCLUDE_LEVEL_5			equ 1
INCLUDE_LEVEL_6			equ 1
INCLUDE_LEVEL_7			equ 1
INCLUDE_LEVEL_8			equ 1
INCLUDE_LEVEL_TST1		equ 0

INCLUDE_CHARACTER_ECHO	equ 1

Z80Program:

	;IF ECHO_ENCRYPT_Z80
	;incbin "FRAMEWORK/ECHO/ECHOZ80E.BIN"
	;ELSE
	;incbin "FRAMEWORK/ECHO/ECHO_Z80.BIN"
	;ENDIF

Z80ProgSize equ *-Z80Program
    even


