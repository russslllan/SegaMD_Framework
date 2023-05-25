spriteSonic3:
    incbin 'spriteSonic3.dat'

spriteSonic3End								             ; Sprite end address
spriteSonic3SizeB: equ (spriteSonic3End-spriteSonic3)	 ; Sprite size in bytes
spriteSonic3SizeW: equ (spriteSonic3SizeB/2)		     ; Sprite size in words
spriteSonic3SizeL: equ (spriteSonic3SizeB/4)		     ; Sprite size in longs
spriteSonic3SizeT: equ (spriteSonic3SizeB/32)		     ; Sprite size in tiles
spriteSonic3TileID: equ (spriteSonic3VRAM/32)		     ; ID of first tile