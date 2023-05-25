; Align 8 bytes
	nop 0,8

FloorLevel:
    dc.l $BBBBBBBB
    dc.l $BBBBBBBB
    dc.l $BBBBBBBB
    dc.l $BBBBBBBB
    dc.l $BBBBBBBB
    dc.l $BBBBBBBB
    dc.l $BBBBBBBB
    dc.l $BBBBBBBB
    
FloorLevelEnd:

FloorLevelSizeB equ (FloorLevelEnd-FloorLevel)
FloorLevelSizeW equ (FloorLevelSizeB/2)
FloorLevelSizeL equ (FloorLevelSizeB/4)
FloorLevelSizeT equ (FloorLevelSizeB/32)