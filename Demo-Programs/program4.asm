MOV X, 6
MOV Y, 3
ST Y, 300
MOVI 0
ADD Y
compara: CMP X
BRN scade
BRA egale
scade: DEC X
BRA compara
egale: ST X, 301
END
