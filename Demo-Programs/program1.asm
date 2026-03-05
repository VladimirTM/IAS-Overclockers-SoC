LD X, 100
MOV Y, 1
MOVI 0
ADD Y
AND X
BRZ par
BRA impar
par: ST X, 102
BRA final
impar: ST X, 103
final: LD X, 102
LD Y, 103
END
