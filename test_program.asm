; IAS-Overclockers CPU Test Program
; Tests all instructions including new extensions:
; JMP, PUSH X/Y, POP X/Y, MOVR, BGT, BLT, BGE, BLE, BEQ, BNE, NOP

; Memory and Control Flow
LD X, 284
LD Y, 285
ST X, 274
ST Y, 275
JMP alu_tests
END

; ALU Register Operations
alu_tests: LD X, 284
LD Y, 285
MOVI 100
ADD X
SUB X
MUL Y
DIV Y
MOD Y
MOVI 3
LSL X
MOVI 16
LSR X
MOVI 255
RSR X
MOVI 240
RSL X
MOVI 170
AND X
MOVI 15
OR X
MOVI 85
XOR X
NOT X

; ALU Immediate Operations
MOVI 200
ADDI 34
SUBI 34
MULI 5
DIVI 10
MODI 17
LSLI 4
LSRI 3
RSRI 2
RSLI 1
ANDI 127
ORI 56
XORI 21
NOTI 0
CMPI 100
TSTI 85

; Register Manipulation
MOV X, 42
MOVI 123
INC X
DEC X
MOV Y, 88
INC Y
DEC Y
LD X, 496
LD Y, 497
MOVI 255

; NEW: MOVR (Register-to-Register Move)
MOVI 42
MOVR X, A
MOVR Y, X
MOVR A, Y

; NEW: BGT (Branch if Greater Than)
MOVI 10
MOV X, 5
CMP X
BGT bgt_pass
END
bgt_pass: NOP

; NEW: BLT (Branch if Less Than)
MOVI 3
MOV X, 7
CMP X
BLT blt_pass
END
blt_pass: NOP

; NEW: BGE (Branch if Greater or Equal)
MOVI 10
MOV X, 5
CMP X
BGE bge_pass
END
bge_pass: NOP

; NEW: BLE (Branch if Less or Equal)
MOVI 5
MOV X, 5
CMP X
BLE ble_pass
END
ble_pass: NOP

; NEW: BEQ (Branch if Equal) - alias for BRZ
MOVI 5
MOV X, 5
CMP X           ; Compare A (5) with X (5) -> Z=1 (equal)
BEQ beq_pass    ; Should branch (Z==1)
END
beq_pass: NOP

; NEW: BNE (Branch if Not Equal)
MOVI 5
MOV X, 10
CMP X           ; Compare A (5) with X (10) -> Z=0 (not equal)
BNE bne_pass    ; Should branch (Z==0)
END
bne_pass: NOP

; Existing Branch Tests
MOVI 50
CMP X
BRZ brz_fail
BRA brz_pass
brz_fail: END
brz_pass: NOP
MOVI -5
CMP X
BRN brn_pass
END
brn_pass: NOP

; Stack Operations (PUSH/POP registers)
MOV X, 77
MOV Y, 88
PUSH X
PUSH Y
MOV X, 11
MOV Y, 22
POP Y
POP X

; I/O and Interrupt Enable/Disable Tests
EI              ; enable interrupts (I_flag = 1)
DI              ; disable interrupts (I_flag = 0)
MOVI 42         ; A = 42 (value to write to display)
OUT 16          ; write A to display port 16
IN 1            ; read KBD_STATUS into A (no strobe → 0)

; Final success marker
MOVI 100
END
