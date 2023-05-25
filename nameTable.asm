nameTable:
    incbin 'nameTable.dat'
nameTableEnd;
nameTableSizeB equ (nameTableEnd-nameTable)
nameTableSizeW equ (nameTableSizeB/2)
nameTableSizeL equ (nameTableSizeB/4)
nameTableSizeT equ (nameTableSizeB/32)